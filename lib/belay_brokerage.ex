defmodule BelayBrokerage do
  @moduledoc """
  BelayBrokerage provides an interface against the BelayBrokerage defined DB
  """
  alias BelayBrokerage.AuthAccount
  alias BelayBrokerage.Transactions
  alias BelayBrokerage.Investor
  alias BelayBrokerage.Holding
  alias BelayBrokerage.Repo

  import Ecto.Query

  require Logger

  @type investor :: %{
          required(:first_name) => String.t(),
          required(:last_name) => String.t(),
          required(:address_1) => String.t(),
          optional(:address_2) => String.t(),
          required(:city) => String.t(),
          required(:region) => String.t(),
          required(:postal_code) => String.t(),
          required(:phone) => String.t(),
          required(:plaid_access_token) => String.t(),
          optional(:plaid_account_id) => String.t(),
          optional(:plaid_item_id) => String.t(),
          optional(:dwolla_customer_id) => String.t(),
          optional(:auth_accounts) => [AuthAccount.t()]
        }

  @spec all_investors(String.t()) :: [Investor.t()]
  def all_investors(partner_id) do
    with [%Investor{} | _] = investors <- Repo.all(Investor, prefix: partner_id) do
      investors
      |> Repo.preload(:auth_accounts)
      |> Enum.map(fn %Investor{auth_accounts: auth_accounts} = investor ->
        %{email: primary_email} = Enum.find(auth_accounts, & &1.is_primary)
        Map.put(investor, :primary_email, primary_email)
      end)
    end
  end

  @spec create_investor(String.t(), String.t(), String.t()) :: {:ok, Investor.t()} | {:error, Ecto.Changeset.t()}
  def create_investor(partner_id, uid, email) do
    %Investor{}
    |> Investor.create_changeset(%{auth_accounts: [%{uid: uid, email: email, is_primary: true}]})
    |> Repo.insert(prefix: partner_id)
  end

  @spec update_investor(String.t(), String.t(), investor()) ::
          {:ok, Investor.t()} | {:error, :investor_not_found | Ecto.Changeset.t()}
  def update_investor(partner_id, investor_id, params) do
    case get_investor(partner_id, investor_id) do
      %Investor{} = investor ->
        investor
        |> Investor.linked_changeset(params)
        |> Repo.update()

      nil ->
        {:error, :investor_not_found}
    end
  end

  @spec get_investor(String.t(), String.t()) :: Investor.t() | nil
  def get_investor(partner_id, investor_id) do
    with %Investor{} = investor <- Repo.get(Investor, investor_id, prefix: partner_id) do
      %{email: primary_email} = fetch_primary_account(investor)

      Map.put(investor, :primary_email, primary_email)
    end
  end

  @spec get_investor_by_email(String.t(), String.t()) :: Investor.t() | nil
  def get_investor_by_email(partner_id, email) do
    query = from(a in AuthAccount, prefix: ^partner_id, where: a.email == ^email)

    case Repo.all(query) do
      [] ->
        nil

      auth_accounts ->
        auth_account = Enum.find(auth_accounts, & &1.is_primary)
        get_investor(partner_id, auth_account.investor_id)
    end
  end

  @spec get_investor_by_plaid_item_id(String.t(), String.t()) :: Investor.t() | nil
  def get_investor_by_plaid_item_id(partner_id, plaid_item_id) do
    query = from(i in Investor, where: i.plaid_item_id == ^plaid_item_id)

    with %Investor{} = investor <- Repo.one(query, prefix: partner_id) do
      %{email: primary_email} = fetch_primary_account(investor)

      Map.put(investor, :primary_email, primary_email)
    end
  end

  @spec holding_transaction(String.t(), String.t(), String.t(), Decimal.t(), String.t()) ::
          {:ok, Holding.t()} | {:error, Ecto.Changeset.t()}
  def holding_transaction(partner_id, investor_id, sym, delta_qty, brokerage) do
    Repo.transaction(fn ->
      case insert_update_or_delete_holding(partner_id, investor_id, sym, delta_qty, brokerage) do
        {:ok, holding} ->
          :ok = Transactions.publish_transaction(investor_id, sym, delta_qty)
          holding

        {:error, reason} ->
          Logger.error("Unable to insert/update/delete holding: #{inspect(reason)}", reason: reason)
          Repo.rollback(reason)
      end
    end)
  end

  @spec get_holdings(String.t(), String.t()) :: Holding.t()
  def get_holdings(partner_id, investor_id) do
    query = from(h in Holding, where: h.investor_id == ^investor_id)

    Repo.all(query, prefix: partner_id)
  end

  @spec configure_tenants_up() :: :ok
  def configure_tenants_up() do
    Ecto.Migrator.with_repo(BelayBrokerage.Repo, fn repo ->
      desired_tenants = Application.get_env(:belay_brokerage, :tenants)
      current_tenants = Triplex.all(repo)
      changes = List.myers_difference(current_tenants, desired_tenants)

      for tenant <- Keyword.get(changes, :ins, []) do
        Triplex.create(tenant, repo)
      end

      for tenant <- Keyword.get(changes, :eq, []) do
        Ecto.Migrator.run(repo, Triplex.migrations_path(repo), :up, all: true, prefix: tenant)
      end
    end)

    :ok
  end

  @spec configure_tenants_down(Integer.t()) :: :ok
  def configure_tenants_down(version) do
    Ecto.Migrator.with_repo(BelayBrokerage.Repo, fn repo ->
      for tenant <- Triplex.all(repo) do
        Ecto.Migrator.run(repo, Triplex.migrations_path(repo), :down, to: version, prefix: tenant)
      end
    end)

    :ok
  end

  defp insert_update_or_delete_holding(partner_id, investor_id, sym, delta_qty, brokerage) do
    case Repo.get_by(Holding, [investor_id: investor_id, sym: sym], prefix: partner_id) do
      nil ->
        %Holding{}
        |> Holding.changeset(%{investor_id: investor_id, sym: sym, qty: delta_qty, brokerage: brokerage})
        |> Repo.insert(prefix: partner_id)

      holding ->
        new_qty = Decimal.add(holding.qty, delta_qty)

        if Decimal.compare(new_qty, Decimal.new(0)) == :gt do
          holding |> Holding.update_qty_changeset(new_qty) |> Repo.update(prefix: partner_id)
        else
          Repo.delete(holding, prefix: partner_id)
        end
    end
  end

  defp fetch_primary_account(%Investor{} = investor) do
    %Investor{auth_accounts: auth_accounts} = Repo.preload(investor, :auth_accounts)
    Enum.find(auth_accounts, & &1.is_primary)
  end
end

defmodule BelayBrokerage do
  @moduledoc """
  BelayBrokerage provides an interface against the BelayBrokerage defined DB
  """
  alias BelayBrokerage.Investor
  alias BelayBrokerage.Repo

  @type investor :: %{
          required(:first_name) => String.t(),
          required(:last_name) => String.t(),
          required(:address_1) => String.t(),
          optional(:address_2) => String.t(),
          required(:city) => String.t(),
          required(:region) => String.t(),
          required(:postal_code) => String.t(),
          required(:email) => String.t(),
          required(:phone) => String.t()
        }

  @spec all_investors(String.t()) :: [Investor.t()]
  def all_investors(partner_id) do
    Repo.all(Investor, prefix: partner_id)
  end

  @spec create_investor(String.t(), investor()) ::
          {:ok, Investor.t()} | {:error, Ecto.Changeset.t()}
  def create_investor(partner_id, attrs) do
    attrs
    |> Investor.new!()
    |> Repo.insert(prefix: partner_id)
  end

  @spec get_investor(String.t(), String.t()) :: Investor.t() | nil
  def get_investor(partner_id, investor_id) do
    Repo.get(Investor, investor_id, prefix: partner_id)
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
end

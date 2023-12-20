defmodule BelayBrokerage do
  @moduledoc """
  BelayBrokerage provides an interface agaisnt the BelayBrokerage defined DB
  """
  alias BelayBrokerage.Investor
  alias BelayBrokerage.Repo

  def all_investors(partner_id) do
    Repo.all(Investor, prefix: partner_id)
  end

  def create_investor(partner_id, attrs) do
    Investor.new!(attrs)
    |> Repo.insert!(prefix: partner_id)
  end

  def get_investor(partner_id, investor_id) do
    Repo.get(Investor, investor_id, prefix: partner_id)
  end

  def configure_tenants_up() do
    Ecto.Migrator.with_repo(BelayBrokerage.Repo, fn repo ->
      desired_tenants = Application.get_env(:belay_brokerage, :tenants)
      current_tenants = Triplex.all(repo)
      changes = List.myers_difference(current_tenants, desired_tenants)

      for tenant <- Keyword.get(changes, :ins, []) do
        Triplex.create(tenant, repo)
      end

      for tenant <- Keyword.get(changes, :del, []) do
        Triplex.drop(tenant, repo)
      end

      for tenant <- Keyword.get(changes, :eq, []) do
        Ecto.Migrator.run(repo, Triplex.migrations_path(repo), :up, all: true, prefix: tenant)
      end
    end)
  end

  def configure_tenants_down(version) do
    Ecto.Migrator.with_repo(BelayBrokerage.Repo, fn repo ->
      for tenant <- Triplex.all(repo) do
        Ecto.Migrator.run(repo, Triplex.migrations_path(repo), :down, to: version, prefix: tenant)
      end
    end)
  end
end

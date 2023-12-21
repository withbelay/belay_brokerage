defmodule Mix.Tasks.BelayBrokerage.SetupTenants do
  @moduledoc """
  Create a partner in Triplex and Partners table for dev and test purposes.
  Meant to be ran in the testing and dev environment. Run with:

  `mix belay_brokerage.setup_tenants`
  """
  require Logger
  use Mix.Task

  @requirements ["app.config"]

  @impl Mix.Task
  def run(_args) do
    Ecto.Migrator.with_repo(BelayBrokerage.Repo, fn repo ->
      for tenant <- Application.fetch_env!(:belay_brokerage, :tenants) do
        {:ok, _} = Triplex.create(tenant, repo)
      end
    end)
  end
end

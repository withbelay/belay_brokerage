defmodule BelayBrokerage.DataCase do
  @moduledoc """
  This module defines the test case to be used by
  tests that require setting up a database connection.

  Finally, if the test case interacts with the database,
  we enable the SQL sandbox, so changes done to the database
  are reverted at the end of every test. If you are using
  PostgreSQL, you can even run database tests asynchronously
  by setting `use BelayBrokerage.DataCase, async: true`, although
  this option is not recommended for other databases.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      @default_tenant Application.compile_env!(:belay_brokerage, :tenants) |> List.first()
    end
  end

  setup tags do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(BelayBrokerage.Repo)

    case tags[:async] do
      true ->
        Ecto.Adapters.SQL.Sandbox.mode(BelayBrokerage.Repo, :manual)

      _ ->
        Ecto.Adapters.SQL.Sandbox.mode(BelayBrokerage.Repo, {:shared, self()})
    end

    :ok
  end
end

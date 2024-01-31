defmodule BelayBrokerage.Transactions.Connection do
  use Rabbit.Connection

  def start_link(opts \\ []) do
    Rabbit.Connection.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl Rabbit.Connection
  def init(:connection_pool, opts), do: {:ok, opts}

  def init(:connection, _opts) do
    # Perform runtime connection config
    opts = Application.fetch_env!(:belay_brokerage, :rabbit_connection_opts)

    {:ok, opts}
  end
end

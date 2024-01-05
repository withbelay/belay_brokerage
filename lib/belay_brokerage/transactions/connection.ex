defmodule BelayBrokerage.Transactions.Connection do
  use Rabbit.Connection

  def start_link(opts \\ []) do
    Rabbit.Connection.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl Rabbit.Connection
  def init(:connection_pool, opts), do: {:ok, opts}

  def init(:connection, opts) do
    # Perform runtime connection config
    uri = Application.fetch_env!(:belay_brokerage, :rabbit_uri)
    opts = Keyword.put(opts, :uri, uri)

    {:ok, opts}
  end
end

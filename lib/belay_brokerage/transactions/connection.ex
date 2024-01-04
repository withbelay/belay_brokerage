defmodule BelayBrokerage.Transactions.Connection do
  use Rabbit.Connection

  def start_link(opts \\ []) do
    Rabbit.Connection.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl Rabbit.Connection
  def init(:connection_pool, opts), do: {:ok, opts}

  def init(:connection, opts) do
    # Perform runtime connection config
    uri = System.get_env("RABBITMQ_URI", "amqp://guest:guest@localhost")
    opts = Keyword.put(opts, :uri, uri)

    {:ok, opts}
  end
end

defmodule BelayBrokerage.Transactions.Producer do
  use Rabbit.Producer

  def start_link(opts \\ []) do
    Rabbit.Producer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl Rabbit.Producer
  def init(:producer_pool, opts), do: {:ok, opts}
  def init(:producer, opts), do: {:ok, opts}
end

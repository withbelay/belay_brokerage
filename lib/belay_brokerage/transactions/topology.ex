defmodule BelayBrokerage.Transactions.Topology do
  use Rabbit.Topology

  def start_link(opts \\ []) do
    Rabbit.Topology.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl Rabbit.Topology
  def init(:topology, opts), do: {:ok, opts}
end

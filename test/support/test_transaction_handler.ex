defmodule BelayBrokerage.TestTransactionHandler do
  use Agent

  @behaviour BelayBrokerage.Transactions.Handler

  def start_link(test_pid) do
    Agent.start_link(fn -> test_pid end, name: __MODULE__)
  end

  @impl BelayBrokerage.Transactions.Handler
  def handle_message(msg) do
    test_pid = Agent.get(__MODULE__, & &1)
    send(test_pid, {:handle_message, msg})

    {:ack, msg}
  end

  @impl BelayBrokerage.Transactions.Handler
  def handle_error(msg) do
    test_pid = Agent.get(__MODULE__, & &1)
    send(test_pid, {:handle_message, msg})

    {:ack, msg}
  end
end

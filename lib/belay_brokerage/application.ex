defmodule BelayBrokerage.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    transaction_handler_type = Application.fetch_env!(:belay_brokerage, :transaction_handler_type)

    children =
      [
        BelayBrokerage.Repo,
        BelayBrokerage.Transactions.Connection,
        {BelayBrokerage.Transactions.Topology,
         connection: BelayBrokerage.Transactions.Connection,
         queues: [
           [name: "belaybrokerage_transactions_v2", durable: true, arguments: [{"x-single-active-consumer", true}]]
         ],
         exchanges: [[name: "belaybrokerage_exchange", type: :fanout]],
         bindings: [
           [
             type: :queue,
             source: "belaybrokerage_exchange",
             destination: "belaybrokerage_transactions"
           ]
         ]}
      ] ++
        transaction_children(transaction_handler_type)

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: BelayBrokerage.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp transaction_children(:producer) do
    [{BelayBrokerage.Transactions.Producer, connection: BelayBrokerage.Transactions.Connection}]
  end

  defp transaction_children(:consumer) do
    [
      {BelayBrokerage.Transactions.Consumer,
       connection: BelayBrokerage.Transactions.Connection, queue: "belaybrokerage_transactions"}
    ]
  end

  defp transaction_children(:producer_consumer) do
    [
      {BelayBrokerage.Transactions.Producer, connection: BelayBrokerage.Transactions.Connection},
      {BelayBrokerage.Transactions.Consumer,
       connection: BelayBrokerage.Transactions.Connection, queue: "belaybrokerage_transactions"}
    ]
  end
end

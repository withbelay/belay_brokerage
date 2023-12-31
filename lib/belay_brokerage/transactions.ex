defmodule BelayBrokerage.Transactions do
  @belaybrokerage_exchange "belaybrokerage_exchange"
  @belaybrokerage_transactions_queue "belaybrokerage_transactions"

  defmodule Handler do
    @moduledoc """
    A behaviour meant to be used by a consumer.

    ## Example:

    ```elixir
    defmodule MyApp.TransactionListener do
      @behaviour BelayBrokerage.Transactions.Handler

      @impl BelayBrokerage.Transactions.Handler
      def handle_message(msg) do
        IO.inspect(Jason.decode!(msg.payload))

        {:ack, msg}
      end

      @impl BelayBrokerage.Transactions.Handler
      def handle_error(msg) do
        IO.inspect(Jason.decode!(msg.payload))

        {:ack, msg}
      end
    end
    ```
    """
    @callback handle_message(Rabbit.Message.t()) :: Rabbit.Consumer.message_response()
    @callback handle_error(Rabbit.Message.t()) :: Rabbit.Consumer.message_response()
  end

  defmodule Message do
    use BelayBrokerage.SimpleTypedSchema

    @derive Jason.Encoder
    typed_embedded_schema do
      field(:investor_id, :string)
      field(:sym, :string)
      field(:qty, :decimal)
      field(:type, Ecto.Enum, values: [:buy, :sell])
    end

    def_new(required: :all)
  end

  @spec publish_transaction(String.t(), String.t(), Decimal.t()) :: :ok | {:error, any()}
  def publish_transaction(investor_id, sym, qty) do
    transaction_type = if Decimal.gt?(qty, Decimal.new(0)), do: :buy, else: :sell

    Rabbit.Producer.publish(
      BelayBrokerage.Transactions.Producer,
      @belaybrokerage_exchange,
      @belaybrokerage_transactions_queue,
      Message.new!(%{investor_id: investor_id, sym: sym, qty: qty, type: transaction_type}),
      content_type: "application/json"
    )
  end
end

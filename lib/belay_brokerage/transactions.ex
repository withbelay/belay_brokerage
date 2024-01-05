defmodule BelayBrokerage.Transactions do
  @belaybrokerage_exchange "belaybrokerage_exchange"
  @belaybrokerage_transactions_queue "belaybrokerage_transactions"

  @callback handle_message(Rabbit.Message.t()) :: Rabbit.Consumer.message_response()
  @callback handle_error(Rabbit.Message.t()) :: Rabbit.Consumer.message_response()

  defmodule Message do
    use BelayBrokerage.SimpleTypedSchema

    @derive Jason.Encoder
    typed_embedded_schema do
      field(:investor_id, :string)
      field(:sym, :string)
      field(:qty, :decimal)
    end

    def_new(required: :all)
  end

  @spec publish_transaction(String.t(), String.t(), Decimal.t()) :: :ok | {:error, any()}
  def publish_transaction(investor_id, sym, qty) do
    Rabbit.Producer.publish(
      BelayBrokerage.Transactions.Producer,
      @belaybrokerage_exchange,
      @belaybrokerage_transactions_queue,
      Message.new!(%{investor_id: investor_id, sym: sym, qty: qty}),
      content_type: "application/json"
    )
  end
end

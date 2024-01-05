defmodule BelayBrokerage.Transactions do
  @belaybrokerage_exchange "belaybrokerage_exchange"
  @belaybrokerage_transactions_queue "belaybrokerage_transactions"

  @callback handle_message(Rabbit.Message.t()) :: Rabbit.Consumer.message_response()
  @callback handle_error(Rabbit.Message.t()) :: Rabbit.Consumer.message_response()

  @spec publish(String.t()) :: :ok | {:error, any()}
  def publish(msg) do
    Rabbit.Producer.publish(
      BelayBrokerage.Transactions.Producer,
      @belaybrokerage_exchange,
      @belaybrokerage_transactions_queue,
      msg
    )
  end
end

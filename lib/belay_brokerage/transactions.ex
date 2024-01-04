defmodule BelayBrokerage.Transactions do
  @belaybrokerage_exchange "belaybrokerage_exchange"
  @belaybrokerage_transactions_queue "belaybrokerage_transactions"

  @callback handle_message(String.t()) :: Rabbit.Consumer.message_response()
  @callback handle_error(String.t()) :: Rabbit.Consumer.message_response()

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

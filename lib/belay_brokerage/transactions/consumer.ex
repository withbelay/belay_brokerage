defmodule BelayBrokerage.Transactions.Consumer do
  use Rabbit.Consumer

  def start_link(opts \\ []) do
    Rabbit.Consumer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl Rabbit.Consumer
  def init(:consumer, opts), do: {:ok, opts}

  @impl true
  def handle_message(message) do
    transaction_handler().handle_message(message.payload)
  end

  @impl true
  def handle_error(message) do
    transaction_handler().handle_error(message.payload)
  end

  defp transaction_handler, do: Application.fetch_env!(:belay_brokerage, :transaction_handler)
end

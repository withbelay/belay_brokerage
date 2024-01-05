defmodule BelayBrokerage.Holding do
  use BelayBrokerage.SimpleTypedSchema

  typed_schema "holdings" do
    field(:investor_id, :string, primary_key: true)
    field(:sym, :string)
    field(:qty, :decimal)

    timestamps()
  end

  def_new(required: ~w(sym qty investor_id)a)
end

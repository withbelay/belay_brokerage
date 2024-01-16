defmodule BelayBrokerage.Holding do
  use BelayBrokerage.SimpleTypedSchema

  typed_schema "holdings" do
    field(:investor_id, :string, primary_key: true)
    field(:sym, :string, primary_key: true)
    field(:qty, :decimal)
    field(:brokerage, :string)

    timestamps()
  end

  def update_qty_changeset(%__MODULE__{} = holding, new_qty) do
    change(holding, qty: new_qty)
  end

  def_new(required: ~w(sym qty investor_id brokerage)a)
end

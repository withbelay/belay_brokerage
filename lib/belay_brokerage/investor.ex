defmodule BelayBrokerage.Investor do
  use BelayBrokerage.SimpleTypedSchema

  @primary_key {:id, :string, autogenerate: false}
  typed_schema "investors" do
    field(:first_name, :string)
    field(:last_name, :string)
    field(:address_1, :string)
    field(:address_2, :string)
    field(:city, :string)
    field(:region, :string)
    field(:postal_code, :string)
    field(:email, :string)
    field(:phone, :string)

    timestamps()
  end

  def_new(
    required: ~w(first_name last_name address_1 city region postal_code email phone)a,
    default: [id: {Ecto.UUID, :generate, []}]
  )
end

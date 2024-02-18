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
    field(:phone, :string)
    field(:access_token, :string)
    field(:account_id, :string)
    field(:item_id, :string)
    field(:dwolla_customer_id, :string)

    has_many(:auth_accounts, BelayBrokerage.AuthAccount)

    timestamps()
  end

  def changeset(params) do
    %__MODULE__{}
    |> cast(params, ~w(first_name last_name address_1 city region postal_code phone)a)
    |> cast_assoc(:auth0_ids, with: &BelayBrokerage.AuthAccount.create_changeset/2)
  end

  def_new(
    required: ~w(first_name last_name address_1 city region postal_code phone)a,
    default: [{:id, {Ecto.UUID, :generate, []}}]
  )
end

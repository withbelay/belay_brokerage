defmodule BelayBrokerage.Investor do
  use BelayBrokerage.SimpleTypedSchema

  @primary_key {:id, :string, autogenerate: {Ecto.UUID, :generate, []}}
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

    field(:primary_email, :string, virtual: true)

    has_many(:auth_accounts, BelayBrokerage.AuthAccount)

    timestamps()
  end

  @spec create_changeset(__MODULE__.t(), map()) :: Ecto.Changeset.t()
  def create_changeset(%__MODULE__{} = struct \\ %__MODULE__{}, params) do
    struct
    |> cast(params, [])
    |> cast_assoc(:auth_accounts, required: true, with: &BelayBrokerage.AuthAccount.create_changeset/2)
  end

  def linked_changeset(%__MODULE__{} = struct, params) do
    struct
    |> change(params)
    |> validate_required(
      ~w(first_name last_name address_1 city region postal_code phone access_token account_id item_id dwolla_customer_id)a
    )
  end

  def_new()
end

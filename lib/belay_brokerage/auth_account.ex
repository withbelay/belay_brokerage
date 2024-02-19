defmodule BelayBrokerage.AuthAccount do
  use BelayBrokerage.SimpleTypedSchema

  @primary_key {:uid, :string, autogenerate: false}
  typed_schema "auth_accounts", primary_key: false do
    field(:investor_id, :string)
    field(:email, :string)
    field(:is_primary, :boolean)

    belongs_to(:investor, BelayBrokerage.Investor,
      foreign_key: :investor_id,
      references: :id,
      define_field: false
    )
  end

  @spec create_changeset(__MODULE__.t(), map()) :: Ecto.Changeset.t()
  def create_changeset(%__MODULE__{} = struct \\ %__MODULE__{}, params) do
    struct
    |> changeset(params)
    |> unique_constraint([:email, :investor_id])
    |> foreign_key_constraint(:investor_id)
  end

  def_new(required: ~w(uid email is_primary)a)
end

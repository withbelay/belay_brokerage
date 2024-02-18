defmodule BelayBrokerage.AuthAccount do
  use BelayBrokerage.SimpleTypedSchema

  typed_schema "auth_accounts", primary_key: false do
    field(:uid, :string, primary_key: true)
    field(:investor_id, :string)
    field(:email, :string)
    field(:is_primary, :boolean)

    belongs_to(:investor, BelayBrokerage.AuthAccount,
      foreign_key: :investor_id,
      references: :id,
      define_field: false
    )
  end

  @callback create_changeset(__MODULE__.t(), map()) :: Ecto.Changeset.t()
  def create_changeset(%__MODULE__{} = struct, params) do
    struct
    |> changeset(params)
    |> unique_constraint([:email, :investor_id])
  end

  def_new(required: ~w(uid investor_id email is_primary)a)
end

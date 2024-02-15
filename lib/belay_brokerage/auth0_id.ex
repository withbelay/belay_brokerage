defmodule BelayBrokerage.Auth0Id do
  use BelayBrokerage.SimpleTypedSchema

  typed_schema "auth0_ids", primary_key: false do
    field(:uid, :string, primary_key: true)
    field(:investor_id, :string)

    belongs_to(:investor, BelayBrokerage.Auth0Id,
      foreign_key: :investor_id,
      references: :id,
      define_field: false
    )
  end

  def_new(required: ~w(uid investor_id)a)
end

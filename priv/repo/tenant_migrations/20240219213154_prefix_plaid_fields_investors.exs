defmodule BelayBrokerage.Repo.Migrations.PrefixPlaidFieldsInvestors do
  use Ecto.Migration

  def change do
    rename table(:investors), :access_token, to: :plaid_access_token
    rename table(:investors), :account_id, to: :plaid_account_id
    rename table(:investors), :item_id, to: :plaid_item_id
  end
end

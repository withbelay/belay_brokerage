defmodule BelayBrokerage.Repo.Migrations.AddDwollaCustomerIdToInvestor do
  use Ecto.Migration

  def change do
    alter table(:investors) do
      add :dwolla_customer_id, :string
    end
  end
end

defmodule BelayBrokerage.Repo.Migrations.AddItemIdToInvestor do
  use Ecto.Migration

  def change do
    alter table(:investors) do
      add :item_id, :string
    end
  end
end

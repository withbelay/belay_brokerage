defmodule BelayBrokerage.Repo.Migrations.AddAccountId do
  use Ecto.Migration

  def change do
    alter table(:investors) do
      add :account_id, :string
    end
  end
end

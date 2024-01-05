defmodule BelayBrokerage.Repo.Migrations.CreateHoldings do
  use Ecto.Migration

  def change do
    create table(:holdings, primary_key: false) do
      add(:investor_id, :string, primary_key: true)
      add(:sym, :string)
      add(:qty, :decimal)
    end
  end
end

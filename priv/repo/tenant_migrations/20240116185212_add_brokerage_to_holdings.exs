defmodule BelayBrokerage.Repo.Migrations.AddBrokerageToHoldings do
  use Ecto.Migration

  def change do
    alter table(:holdings) do
      add :brokerage, :string
    end
  end
end

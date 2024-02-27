defmodule BelayBrokerage.Repo.Migrations.RemoveBrokerageFromHoldings do
  use Ecto.Migration

  def change do
    alter table(:holdings) do
      remove :brokerage
    end
  end
end

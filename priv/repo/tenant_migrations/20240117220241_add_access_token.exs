defmodule BelayBrokerage.Repo.Migrations.AddAccessToken do
  use Ecto.Migration

  def change do
    alter table(:investors) do
      add :access_token, :string
    end
  end
end

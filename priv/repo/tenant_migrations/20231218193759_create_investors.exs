defmodule BelayBrokerage.Repo.Migrations.CreateInvestors do
  use Ecto.Migration

  def change do
    create table(:investors, primary_key: false) do
      add(:id, :string, primary_key: true)
      add(:first_name, :string)
      add(:last_name, :string)
      add(:address_1, :string)
      add(:address_2, :string)
      add(:city, :string)
      add(:region, :string)
      add(:postal_code, :string)
      add(:email, :string)
      add(:phone, :string)

      timestamps()
    end
  end
end

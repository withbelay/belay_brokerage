defmodule BelayBrokerage.Repo.Migrations.PreferEmailOverAuth0Uid do
  use Ecto.Migration
  import Ecto.Query

  def up do
    create table(:auth_accounts, primary_key: false) do
      add :uid, :string, primary_key: true
      add :investor_id, references(:investors, type: :string)
      add :email, :string
      add :is_primary, :boolean
    end

    create unique_index(:auth_accounts, [:investor_id, :email])

    flush()

    # Move existing id to auth0_ids table, replace id column in investors table with the email
    investors = repo().all(from i in "investors", prefix: ^prefix(), select: %{id: i.id, email: i.email})

    flush()

    alter table(:investors) do
      remove :email
    end

    flush()

    for %{id: auth0_uid, email: email} <- investors do
      new_investor_id = Ecto.UUID.autogenerate()

      repo().query!("UPDATE #{prefix()}.investors SET id = '#{new_investor_id}' WHERE id = '#{auth0_uid}';")
      repo().query!("INSERT INTO #{prefix()}.auth_accounts (uid, investor_id, email, is_primary) VALUES ('#{auth0_uid}', '#{new_investor_id}', '#{email}', true);")
    end
  end

  def down do
    alter table(:investors) do
      add :email, :string
    end

    flush()

    # Move first existing auth0_id uid back to id column in investors
    query = from i in "investors", select: i.id

    for investor_id <- repo().all(query, prefix: prefix()) do
      query = from a in "auth_accounts", where: a.investor_id == ^investor_id, where: a.is_primary, select: %{uid: a.uid, email: a.email}
      %{uid: uid, email: email} = repo().one(query, prefix: prefix())

      repo().query!("DELETE FROM #{prefix()}.auth_accounts WHERE investor_id = '#{investor_id}';")
      repo().query!("UPDATE #{prefix()}.investors SET id = '#{uid}', email = '#{email}' WHERE id = '#{investor_id}';")
    end

    flush()

    drop unique_index(:auth_accounts, [:investor_id, :email])
    drop table(:auth_accounts)
  end
end

defmodule BelayBrokerage.Repo.Migrations.PreferEmailOverAuth0Uid do
  use Ecto.Migration
  import Ecto.Query

  def up do
    create table(:auth0_ids, primary_key: false) do
      add :uid, :string, primary_key: true
      add :investor_id, references(:investors, type: :string)
    end

    flush()

    # Move existing id to auth0_ids table, replace id column in investors table with the email
    investors = repo().all(from i in "investors", prefix: ^prefix(), select: %{id: i.id, email: i.email})

    repo().query!("UPDATE #{prefix()}.investors SET id = email;")

    for investor <- investors do
      repo().query!("INSERT INTO #{prefix()}.auth0_ids (uid, investor_id) VALUES ('#{investor.id}', '#{investor.email}');")
    end
  end

  def down do
    # Move first existing auth0_id uid back to id column in investors
    query = from i in "investors", select: i.id

    for investor_id <- repo().all(query, prefix: prefix()) do
      query = from a in "auth0_ids", where: a.investor_id == ^investor_id, select: a.uid
      [uid | _] = repo().all(query, prefix: prefix())

      repo().query!("DELETE FROM #{prefix()}.auth0_ids WHERE investor_id = '#{investor_id}';")
      repo().query!("UPDATE #{prefix()}.investors SET id = '#{uid}' WHERE id = '#{investor_id}';")
    end

    flush()

    drop table(:auth0_ids)
  end
end

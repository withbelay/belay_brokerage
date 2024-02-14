defmodule BelayBrokerage.Repo.Migrations.PreferEmailOverAuth0Uid do
  use Ecto.Migration
  import Ecto.Query

  def up do
    alter table(:investors) do
      add :auth0_ids, {:array, :string}
    end

    flush()

    # Move existing id to auth0_ids column, replace id column with the email
    query = from i in "investors", select: %{id: i.id, email: i.email}
    for investor <- repo().all(query, prefix: prefix()) do
      repo().query!("UPDATE #{prefix()}.investors SET id = '#{investor.email}', auth0_ids = '{#{investor.id}}';")
    end
  end

  def down do
    # Move first existing auth0_id back to id column
    query = from i in "investors", select: i.auth0_ids
    for auth0_ids <- repo().all(query, prefix: prefix()) do
      repo().query!("UPDATE #{prefix()}.investors SET id = '#{Enum.at(auth0_ids, 0)}';")
    end

    flush()

    alter table(:investors) do
      remove :auth0_ids
    end
  end
end

defmodule BelayBrokerage.Repo do
  @moduledoc false
  use Ecto.Repo,
    otp_app: :belay_brokerage,
    adapter: Ecto.Adapters.Postgres
end

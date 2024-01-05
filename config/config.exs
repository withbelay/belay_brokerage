import Config

config :belay_brokerage,
  ecto_repos: [BelayBrokerage.Repo]

import_config "#{config_env()}.exs"

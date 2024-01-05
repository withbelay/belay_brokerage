import Config

config :belay_brokerage, BelayBrokerage.Repo,
  url: "postgres://postgres:postgres@localhost/belay_brokerage_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 10

# Print only warnings and errors during test
config :logger, level: :warning

config :belay_brokerage,
  transaction_handler_type: :producer_consumer,
  transaction_handler: BelayBrokerage.TestTransactionHandler,
  rabbit_uri: "amqp://guest:guest@localhost",
  tenants: ["belay_brokerage_test_tenant"]

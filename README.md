# BelayBrokerage

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `belay_brokerage` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:belay_brokerage, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/belay_brokerage>.

## Setup

### All Environments

To setup Belay Brokerage you will need to add the following into your config:

1. You will need to add the BelayBrokerage Repo config into your config files, this config is akin to a normal Ecto.Repo setup

   ```elixir
   config :belay_brokerage, BelayBrokerage.Repo,
     url: "BELAY_BROKERAGE_POSTGRES_URL",
     pool_size: 10
   ```

2. You will need to add `BelayBrokerage.Repo` to the ecto_repos config in your OTP app:

   ```elixir
   config :my_app,
     ecto_repos: [MyApp.Repo, BelayBrokerage.Repo],
   ```

3. You will need to define your tenants that BelayBrokerage will setup

   ```elixir
   config :belay_brokerage, tenants: ["tenant_a", "tenant_b"]
   ```

4. You will need to add a rabbit URI to allow BelayBrokerage to connect to a rabbit instance, decide whether it is a consumer or a producer. If it is a consumer you will need to also reference a Transaction handler module

   **Producer config:**

   ```elixir
   config :belay_brokerage,
     transaction_handler_type: :producer,
     rabbit_uri: "amqp://guest:guest@localhost"
   ```

   **Consumer config:**

   ```elixir
   config :belay_brokerage,
     transaction_handler_type: :consumer,
     transaction_handler: MyApp.TransactionHandler,
     rabbit_uri: "amqp://guest:guest@localhost"
   ```

### Prod / Fly Setup

For fly, be sure to remember to set to IPV6 mode (prod.exs or runtime.exs)

```elixir
config :belay_brokerage, BelayBrokerage.Repo,
  socket_options: [:inet6]
```

### Local Setup

Run: `mix belay_brokerage.setup_tenants` AFTER you run `mix ecto.create` (so that the database exists)

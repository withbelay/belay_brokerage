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

```
config :belay_brokerage, BelayBrokerage.Repo,
  url: "BELAY_BROKERAGE_POSTGRES_URL",
  pool_size: 10
```

2. You will need to add `BelayBrokerage.Repo` to the ecto_repos config in your OTP app:

```
config :my_app,
  ecto_repos: [MyApp.Repo, BelayBrokerage.Repo],
```

3. You will need to define your tenants that BelayBrokerage will setup

```
config :belay_brokerage, tenants: ["tenant_a", "tenant_b"]
```

1. You will need to add a rabbit URI and whether it's a consumer or producer of the transactions

```
config :belay_brokerage,
  transaction_handler_type: :producer | :consumer,
  uri: "amqp://guest:guest@localhost"
```

### Prod / Fly Setup

1. For fly, be sure to remember to set to IPV6 mode (prod.exs or runtime.exs)
```
config :belay_brokerage, BelayBrokerage.Repo,
  socket_options: [:inet6]
```

### Local Setup

1. Run: `mix belay_brokerage.setup_tenants` AFTER you run `mix ecto.create` (so that the database exists)



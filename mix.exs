defmodule BelayBrokerage.MixProject do
  use Mix.Project

  def project do
    [
      app: :belay_brokerage,
      version: "0.1.0",
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {BelayBrokerage.Application, []},
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ecto_sql, "~> 3.10"},
      {:mix_test_watch, "~> 1.0", only: [:dev, :test], runtime: false},
      {:postgrex, ">= 0.0.0"},
      {:triplex, "~> 1.3.0"},
      {:typed_ecto_schema, "~> 0.4.1"}
    ]
  end

  defp aliases do
    [
      "belaybrokerage.ecto.create": ["ecto.create"],
      "belaybrokerage.ecto.migrate": ["setup.belay_brokerage", "triplex.migrate"]
    ]
  end
end

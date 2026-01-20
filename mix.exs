defmodule MiniAstarte.MixProject do
  use Mix.Project

  def project do
    [
      app: :mini_astarte,
      version: "0.1.0",
      elixir: "~> 1.15",
      elixirc_paths: ["lib"],
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger, :crypto],
      mod: {MiniAstarte.Application, []}
    ]
  end

  defp deps do
    [
      {:plug_cowboy, "~> 2.6"},
      {:plug, "~> 1.14"},
      {:jason, "~> 1.4"},
      {:ecto_sql, "~> 3.11"},
      {:ecto_sqlite3, "~> 0.13"},
      {:phoenix_pubsub, "~> 2.1"},
      {:tortoise, "~> 0.10"}
    ]
  end
end

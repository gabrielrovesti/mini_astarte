import Config

config :mini_astarte, ecto_repos: [MiniAstarte.Repo]

config :mini_astarte, MiniAstarte.Repo,
  database: "priv/mini_astarte.db",
  pool_size: 5

config :mini_astarte,
  http_port: 4000,
  mqtt: [host: "localhost", port: 1883, client_id: "mini_astarte"],
  admin_token: "change-me",
  rate_limit: %{max: 60, window_ms: 60_000},
  rules: %{
    "temp" => %{gt: 30.0},
    "humidity" => %{gt: 80.0}
  }

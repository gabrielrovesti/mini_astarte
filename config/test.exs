import Config

config :mini_astarte, MiniAstarte.Repo,
  database: "priv/mini_astarte_test.db",
  pool_size: 1

config :mini_astarte,
  http_port: 4001,
  mqtt: [enabled: false],
  admin_token: "test-token",
  rate_limit: %{max: 1000, window_ms: 60_000}

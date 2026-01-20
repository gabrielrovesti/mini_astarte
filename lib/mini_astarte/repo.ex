defmodule MiniAstarte.Repo do
  use Ecto.Repo,
    otp_app: :mini_astarte,
    adapter: Ecto.Adapters.SQLite3
end

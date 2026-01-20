defmodule MiniAstarte.Application do
  use Application

  def start(_type, _args) do
    children = [
      MiniAstarte.Repo,
      MiniAstarte.RateLimit,
      {Phoenix.PubSub, name: MiniAstarte.PubSub},
      {Plug.Cowboy, scheme: :http, plug: MiniAstarteWeb.Router, options: [port: http_port()]}
    ]

    children =
      if mqtt_enabled?() do
        children ++ [MiniAstarte.Mqtt]
      else
        children
      end

    opts = [strategy: :one_for_one, name: MiniAstarte.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp http_port do
    Application.get_env(:mini_astarte, :http_port, 4000)
  end

  defp mqtt_enabled? do
    mqtt = Application.get_env(:mini_astarte, :mqtt, [])
    Keyword.get(mqtt, :enabled, true)
  end
end

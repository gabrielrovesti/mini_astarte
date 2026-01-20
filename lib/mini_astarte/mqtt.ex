defmodule MiniAstarte.Mqtt do
  def child_spec(args) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [args]},
      type: :worker,
      restart: :permanent,
      shutdown: 500
    }
  end

  def start_link(_args) do
    mqtt = Application.get_env(:mini_astarte, :mqtt, [])
    host = Keyword.get(mqtt, :host, "localhost")
    port = Keyword.get(mqtt, :port, 1883)
    client_id = Keyword.get(mqtt, :client_id, "mini_astarte")

    Tortoise.Connection.start_link(
      client_id: client_id,
      server: {Tortoise.Transport.Tcp, host: host, port: port},
      handler: {MiniAstarte.Mqtt.Handler, []},
      subscriptions: [{"devices/+/data", 0}, {"devices/+/data/+", 0}]
    )
  end
end

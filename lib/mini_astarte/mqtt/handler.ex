defmodule MiniAstarte.Mqtt.Handler do
  use Tortoise.Handler

  def init(_state), do: {:ok, %{}}

  def connection(status, state) do
    {:ok, Map.put(state, :connection, status)}
  end

  def handle_message(["devices", device_id, "data"], payload, state) do
    case Jason.decode(payload) do
      {:ok, data} ->
        _ = MiniAstarte.Ingest.ingest_mqtt(device_id, data)
        {:ok, state}

      _ ->
        {:ok, state}
    end
  end

  def handle_message(_topic, _payload, state), do: {:ok, state}

  def subscription(status, topic_filter, state) do
    new_state = Map.put(state, {:subscribed, topic_filter}, status)
    {:ok, new_state}
  end

  def terminate(_reason, _state), do: :ok
end

defmodule MiniAstarteWeb.Socket do
  @behaviour WebSock

  def init(state) do
    Phoenix.PubSub.subscribe(MiniAstarte.PubSub, "measurements")
    Phoenix.PubSub.subscribe(MiniAstarte.PubSub, "alerts")
    {:ok, state}
  end

  def handle_in(_msg, state), do: {:ok, state}

  def handle_info({:measurement, measurement}, state) do
    payload = %{
      type: "measurement",
      data: %{
        id: measurement.id,
        device_id: measurement.device_id,
        key: measurement.key,
        value: measurement.value,
        ts: DateTime.to_iso8601(measurement.ts)
      }
    }

    {:push, {:text, Jason.encode!(payload)}, state}
  end

  def handle_info({:alert, alert}, state) do
    payload = %{
      type: "alert",
      data: %{
        id: alert.id,
        device_id: alert.device_id,
        rule: alert.rule,
        payload: alert.payload,
        ts: DateTime.to_iso8601(alert.ts)
      }
    }

    {:push, {:text, Jason.encode!(payload)}, state}
  end

  def handle_info(_msg, state), do: {:ok, state}

  def terminate(_reason, _state), do: :ok
end

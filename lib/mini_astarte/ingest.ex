defmodule MiniAstarte.Ingest do
  alias MiniAstarte.Repo
  alias MiniAstarte.Schemas.{Measurement, DeviceState}
  alias MiniAstarte.Devices

  def ingest_http(device_id, token, key, value, ts) do
    ingest(device_id, token, key, value, ts)
  end

  def ingest_mqtt(device_id, token_from_topic, %{"key" => key, "value" => value} = payload) do
    token = Map.get(payload, "token") || token_from_topic
    ingest(device_id, token, key, value, Map.get(payload, "ts"))
  end

  def ingest_mqtt(_device_id, _token_from_topic, _payload), do: {:error, "invalid_payload"}

  defp ingest(device_id, token, key, value, ts) do
    with %{} = device <- Devices.get_device(device_id),
         true <- Devices.valid_token?(device, token),
         :ok <- MiniAstarte.RateLimit.check(device_id),
         {:ok, ts_value} <- parse_ts(ts),
         {:ok, val} <- parse_value(value) do
      changeset =
        Measurement.changeset(%Measurement{}, %{
          device_id: device_id,
          key: key,
          value: val,
          ts: ts_value
        })

      case Repo.insert(changeset) do
        {:ok, measurement} = ok ->
          upsert_state(device_id, key, val, ts_value)
          MiniAstarte.Rules.maybe_alert(device_id, key, val, ts_value)
          MiniAstarte.Streams.broadcast_measurement(measurement)
          ok

        {:error, _changeset} ->
          {:error, "invalid_measurement"}
      end
    else
      nil -> {:error, "unknown_device"}
      false -> {:error, "invalid_token"}
      {:error, "rate_limited"} -> {:error, "rate_limited"}
      {:error, reason} -> {:error, reason}
    end
  end

  defp parse_ts(nil), do: {:ok, DateTime.utc_now()}

  defp parse_ts(ts) when is_binary(ts) do
    case DateTime.from_iso8601(ts) do
      {:ok, dt, _} -> {:ok, dt}
      _ -> {:error, "invalid_ts"}
    end
  end

  defp parse_ts(_), do: {:error, "invalid_ts"}

  defp parse_value(value) when is_integer(value), do: {:ok, value * 1.0}
  defp parse_value(value) when is_float(value), do: {:ok, value}
  defp parse_value(_), do: {:error, "invalid_value"}

  defp upsert_state(device_id, key, value, ts) do
    changeset =
      DeviceState.changeset(%DeviceState{}, %{
        device_id: device_id,
        key: key,
        value: value,
        ts: ts
      })

    Repo.insert(
      changeset,
      on_conflict: [
        set: [value: value, ts: ts, updated_at: NaiveDateTime.utc_now()]
      ],
      conflict_target: [:device_id, :key]
    )
  end
end

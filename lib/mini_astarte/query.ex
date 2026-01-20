defmodule MiniAstarte.Query do
  import Ecto.Query, only: [from: 2]
  alias MiniAstarte.Repo
  alias MiniAstarte.Schemas.{Alert, Measurement, DeviceState}

  def list_measurements(opts \\ %{}) do
    device_id = Map.get(opts, :device_id)
    limit = Map.get(opts, :limit, 50)
    offset = Map.get(opts, :offset, 0)
    from_ts = Map.get(opts, :from)
    to_ts = Map.get(opts, :to)

    query = from(m in Measurement, select: m)
    query = if device_id, do: from(m in query, where: m.device_id == ^device_id), else: query
    query = if from_ts, do: from(m in query, where: m.ts >= ^from_ts), else: query
    query = if to_ts, do: from(m in query, where: m.ts <= ^to_ts), else: query

    query =
      from(m in query,
        order_by: [desc: m.ts],
        limit: ^limit,
        offset: ^offset
      )

    Repo.all(query)
  end

  def list_alerts(opts \\ %{}) do
    device_id = Map.get(opts, :device_id)
    limit = Map.get(opts, :limit, 50)
    offset = Map.get(opts, :offset, 0)
    from_ts = Map.get(opts, :from)
    to_ts = Map.get(opts, :to)

    query = from(a in Alert, select: a)
    query = if device_id, do: from(a in query, where: a.device_id == ^device_id), else: query
    query = if from_ts, do: from(a in query, where: a.ts >= ^from_ts), else: query
    query = if to_ts, do: from(a in query, where: a.ts <= ^to_ts), else: query

    query =
      from(a in query,
        order_by: [desc: a.ts],
        limit: ^limit,
        offset: ^offset
      )

    Repo.all(query)
  end

  def list_states(opts \\ %{}) do
    device_id = Map.get(opts, :device_id)
    limit = Map.get(opts, :limit, 50)
    offset = Map.get(opts, :offset, 0)

    query = from(s in DeviceState, select: s)
    query = if device_id, do: from(s in query, where: s.device_id == ^device_id), else: query

    query =
      from(s in query,
        order_by: [desc: s.updated_at],
        limit: ^limit,
        offset: ^offset
      )

    Repo.all(query)
  end
end

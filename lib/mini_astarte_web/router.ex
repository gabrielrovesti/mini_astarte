defmodule MiniAstarteWeb.Router do
  use Plug.Router

  plug Plug.Logger
  plug Plug.Parsers,
    parsers: [:json],
    pass: ["application/json"],
    json_decoder: Jason

  plug :match
  plug :dispatch

  post "/api/devices" do
    params = conn.body_params
    id = Map.get(params, "id")
    name = Map.get(params, "name")

    case MiniAstarte.Devices.register_device(id, name) do
      {:ok, device} ->
        send_json(conn, 201, %{id: device.id, token: device.token})

      {:error, changeset} ->
        send_json(conn, 400, %{error: "invalid_device", details: errors(changeset)})
    end
  end

  post "/api/ingest" do
    params = conn.body_params
    token = Map.get(params, "token") || token_from_headers(conn)

    result =
      MiniAstarte.Ingest.ingest_http(
        Map.get(params, "device_id"),
        token,
        Map.get(params, "key"),
        Map.get(params, "value"),
        Map.get(params, "ts")
      )

    case result do
      {:ok, measurement} ->
        send_json(conn, 202, %{id: measurement.id})

      {:error, reason} ->
        send_json(conn, 400, %{error: reason})
    end
  end

  get "/api/measurements" do
    conn = fetch_query_params(conn)
    device_id = Map.get(conn.params, "device_id")
    limit = parse_limit(conn.params["limit"])
    offset = parse_offset(conn.params["offset"])
    with {:ok, from_ts} <- parse_datetime(conn.params["from"]),
         {:ok, to_ts} <- parse_datetime(conn.params["to"]) do
      data =
        MiniAstarte.Query.list_measurements(%{
          device_id: device_id,
          limit: limit,
          offset: offset,
          from: from_ts,
          to: to_ts
        })

      send_json(conn, 200, %{data: Enum.map(data, &format_measurement/1)})
    else
      {:error, msg} -> send_json(conn, 400, %{error: msg})
    end
  end

  get "/api/alerts" do
    conn = fetch_query_params(conn)
    device_id = Map.get(conn.params, "device_id")
    limit = parse_limit(conn.params["limit"])
    offset = parse_offset(conn.params["offset"])
    with {:ok, from_ts} <- parse_datetime(conn.params["from"]),
         {:ok, to_ts} <- parse_datetime(conn.params["to"]) do
      data =
        MiniAstarte.Query.list_alerts(%{
          device_id: device_id,
          limit: limit,
          offset: offset,
          from: from_ts,
          to: to_ts
        })

      send_json(conn, 200, %{data: Enum.map(data, &format_alert/1)})
    else
      {:error, msg} -> send_json(conn, 400, %{error: msg})
    end
  end

  get "/api/rules" do
    conn = fetch_query_params(conn)
    device_id = Map.get(conn.params, "device_id")
    limit = parse_limit(conn.params["limit"])
    offset = parse_offset(conn.params["offset"])
    data = MiniAstarte.Rules.list_rules(%{device_id: device_id, limit: limit, offset: offset})
    send_json(conn, 200, %{data: Enum.map(data, &format_rule/1)})
  end

  post "/api/rules" do
    params = conn.body_params

    if admin_authorized?(conn) do
      case MiniAstarte.Rules.create_rule(params) do
        {:ok, rule} ->
          send_json(conn, 201, %{data: format_rule(rule)})

        {:error, changeset} ->
          send_json(conn, 400, %{error: "invalid_rule", details: errors(changeset)})
      end
    else
      send_json(conn, 401, %{error: "unauthorized"})
    end
  end

  put "/api/rules/:id" do
    params = conn.body_params

    if admin_authorized?(conn) do
      case MiniAstarte.Rules.get_rule(id) do
        nil ->
          send_json(conn, 404, %{error: "not_found"})

        rule ->
          case MiniAstarte.Rules.update_rule(rule, params) do
            {:ok, updated} ->
              send_json(conn, 200, %{data: format_rule(updated)})

            {:error, changeset} ->
              send_json(conn, 400, %{error: "invalid_rule", details: errors(changeset)})
          end
      end
    else
      send_json(conn, 401, %{error: "unauthorized"})
    end
  end

  delete "/api/rules/:id" do
    if admin_authorized?(conn) do
      case MiniAstarte.Rules.get_rule(id) do
        nil ->
          send_json(conn, 404, %{error: "not_found"})

        rule ->
          {:ok, _} = MiniAstarte.Rules.delete_rule(rule)
          send_json(conn, 200, %{ok: true})
      end
    else
      send_json(conn, 401, %{error: "unauthorized"})
    end
  end

  get "/dashboard" do
    html = dashboard_html()
    conn
    |> put_resp_content_type("text/html")
    |> send_resp(200, html)
  end

  match _ do
    send_resp(conn, 404, "not_found")
  end

  defp send_json(conn, status, data) do
    body = Jason.encode!(data)
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(status, body)
  end

  defp errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
  end

  defp token_from_headers(conn) do
    case get_req_header(conn, "authorization") do
      ["Bearer " <> token] -> token
      _ ->
        case get_req_header(conn, "x-device-token") do
          [token] -> token
          _ -> nil
        end
    end
  end

  defp parse_limit(nil), do: 50
  defp parse_limit(value) when is_binary(value) do
    case Integer.parse(value) do
      {num, ""} when num > 0 and num <= 500 -> num
      _ -> 50
    end
  end
  defp parse_limit(_), do: 50

  defp parse_offset(nil), do: 0
  defp parse_offset(value) when is_binary(value) do
    case Integer.parse(value) do
      {num, ""} when num >= 0 and num <= 10_000 -> num
      _ -> 0
    end
  end
  defp parse_offset(_), do: 0

  defp parse_datetime(nil), do: {:ok, nil}
  defp parse_datetime(value) when is_binary(value) do
    case DateTime.from_iso8601(value) do
      {:ok, dt, _} -> {:ok, dt}
      _ -> {:error, "invalid_datetime"}
    end
  end
  defp parse_datetime(_), do: {:error, "invalid_datetime"}

  defp format_measurement(measurement) do
    %{
      id: measurement.id,
      device_id: measurement.device_id,
      key: measurement.key,
      value: measurement.value,
      ts: DateTime.to_iso8601(measurement.ts)
    }
  end

  defp format_alert(alert) do
    %{
      id: alert.id,
      device_id: alert.device_id,
      rule: alert.rule,
      payload: alert.payload,
      ts: DateTime.to_iso8601(alert.ts)
    }
  end

  defp format_rule(rule) do
    %{
      id: rule.id,
      device_id: rule.device_id,
      key: rule.key,
      op: rule.op,
      value: rule.value,
      enabled: rule.enabled,
      inserted_at: DateTime.to_iso8601(rule.inserted_at)
    }
  end

  defp admin_authorized?(conn) do
    token = Application.get_env(:mini_astarte, :admin_token, "change-me")

    cond do
      token == "change-me" ->
        false

      match?([^token], get_req_header(conn, "x-admin-token")) ->
        true

      match?(["Bearer " <> ^token], get_req_header(conn, "authorization")) ->
        true

      true ->
        false
    end
  end

  defp dashboard_html do
    """
    <!doctype html>
    <html lang="en">
    <head>
      <meta charset="utf-8" />
      <meta name="viewport" content="width=device-width, initial-scale=1" />
      <title>MiniAstarte Dashboard</title>
      <style>
        body { font-family: "Georgia", serif; background: #f3efe8; color: #2b2a28; margin: 0; }
        header { padding: 24px 32px; background: #d7cbb7; border-bottom: 2px solid #b7a78f; }
        h1 { margin: 0; font-size: 28px; letter-spacing: 0.5px; }
        main { padding: 24px 32px; display: grid; gap: 24px; grid-template-columns: 1fr; }
        section { background: #fffdf9; border: 1px solid #e1d6c5; padding: 16px; }
        table { width: 100%; border-collapse: collapse; font-size: 14px; }
        th, td { text-align: left; padding: 6px 8px; border-bottom: 1px solid #eee3d3; }
        .controls { display: flex; gap: 8px; align-items: center; margin-bottom: 12px; }
        input { padding: 6px 8px; border: 1px solid #c8b89f; }
        button { padding: 6px 10px; border: 1px solid #8b7a62; background: #a48b6a; color: #fff; cursor: pointer; }
      </style>
    </head>
    <body>
      <header>
        <h1>MiniAstarte</h1>
      </header>
      <main>
        <section>
          <div class="controls">
            <label>Device ID</label>
            <input id="deviceId" placeholder="dev-1" />
            <label>From</label>
            <input id="fromTs" placeholder="2026-01-19T16:00:00Z" />
            <label>To</label>
            <input id="toTs" placeholder="2026-01-19T18:00:00Z" />
            <label>Limit</label>
            <input id="limit" placeholder="50" value="50" />
            <label>Offset</label>
            <input id="offset" placeholder="0" value="0" />
            <button id="refresh">Refresh</button>
          </div>
          <h2>Measurements</h2>
          <table>
            <thead><tr><th>Time</th><th>Device</th><th>Key</th><th>Value</th></tr></thead>
            <tbody id="measurements"></tbody>
          </table>
        </section>
        <section>
          <h2>Alerts</h2>
          <table>
            <thead><tr><th>Time</th><th>Device</th><th>Rule</th><th>Payload</th></tr></thead>
            <tbody id="alerts"></tbody>
          </table>
        </section>
        <section>
          <h2>Rules</h2>
          <div class="controls">
            <label>Admin Token</label>
            <input id="adminToken" placeholder="x-admin-token" />
            <label>Device ID (optional)</label>
            <input id="ruleDeviceId" placeholder="dev-1" />
            <label>Key</label>
            <input id="ruleKey" placeholder="temp" />
            <label>Op</label>
            <input id="ruleOp" placeholder="gt" />
            <label>Value</label>
            <input id="ruleValue" placeholder="30.0" />
            <label>Enabled</label>
            <input id="ruleEnabled" placeholder="true" value="true" />
            <button id="createRule">Create</button>
          </div>
          <table>
            <thead><tr><th>ID</th><th>Device</th><th>Key</th><th>Op</th><th>Value</th><th>Enabled</th><th>Actions</th></tr></thead>
            <tbody id="rules"></tbody>
          </table>
        </section>
      </main>
      <script>
        async function loadData() {
          const deviceId = document.getElementById("deviceId").value.trim();
          const fromTs = document.getElementById("fromTs").value.trim();
          const toTs = document.getElementById("toTs").value.trim();
          const limit = document.getElementById("limit").value.trim();
          const offset = document.getElementById("offset").value.trim();
          const params = new URLSearchParams();
          if (deviceId) params.append("device_id", deviceId);
          if (fromTs) params.append("from", fromTs);
          if (toTs) params.append("to", toTs);
          if (limit) params.append("limit", limit);
          if (offset) params.append("offset", offset);
          const qs = params.toString() ? `?${params.toString()}` : "";
          const [mRes, aRes] = await Promise.all([
            fetch(`/api/measurements${qs}`),
            fetch(`/api/alerts${qs}`)
          ]);
          const mData = (await mRes.json()).data || [];
          const aData = (await aRes.json()).data || [];
          document.getElementById("measurements").innerHTML = mData.map(row =>
            `<tr><td>${row.ts}</td><td>${row.device_id}</td><td>${row.key}</td><td>${row.value}</td></tr>`
          ).join("");
          document.getElementById("alerts").innerHTML = aData.map(row =>
            `<tr><td>${row.ts}</td><td>${row.device_id}</td><td>${row.rule}</td><td>${JSON.stringify(row.payload)}</td></tr>`
          ).join("");
        }
        async function loadRules() {
          const res = await fetch(`/api/rules`);
          const data = (await res.json()).data || [];
          document.getElementById("rules").innerHTML = data.map(row => `
            <tr>
              <td>${row.id}</td>
              <td>${row.device_id || ""}</td>
              <td>${row.key}</td>
              <td>${row.op}</td>
              <td>${row.value}</td>
              <td>${row.enabled}</td>
              <td>
                <button data-id="${row.id}" data-enabled="${row.enabled}" class="toggleRule">Toggle</button>
                <button data-id="${row.id}" class="deleteRule">Delete</button>
              </td>
            </tr>
          `).join("");
        }
        async function createRule() {
          const token = document.getElementById("adminToken").value.trim();
          const deviceId = document.getElementById("ruleDeviceId").value.trim();
          const key = document.getElementById("ruleKey").value.trim();
          const op = document.getElementById("ruleOp").value.trim();
          const value = parseFloat(document.getElementById("ruleValue").value.trim());
          const enabled = document.getElementById("ruleEnabled").value.trim().toLowerCase() !== "false";
          const payload = { key, op, value, enabled };
          if (deviceId) payload.device_id = deviceId;
          await fetch("/api/rules", {
            method: "POST",
            headers: { "Content-Type": "application/json", "x-admin-token": token },
            body: JSON.stringify(payload)
          });
          loadRules();
        }
        async function toggleRule(id, enabled) {
          const token = document.getElementById("adminToken").value.trim();
          await fetch(`/api/rules/${id}`, {
            method: "PUT",
            headers: { "Content-Type": "application/json", "x-admin-token": token },
            body: JSON.stringify({ enabled: !enabled })
          });
          loadRules();
        }
        async function deleteRule(id) {
          const token = document.getElementById("adminToken").value.trim();
          await fetch(`/api/rules/${id}`, {
            method: "DELETE",
            headers: { "x-admin-token": token }
          });
          loadRules();
        }
        document.getElementById("refresh").addEventListener("click", loadData);
        document.getElementById("createRule").addEventListener("click", createRule);
        document.getElementById("rules").addEventListener("click", (event) => {
          const target = event.target;
          if (target.classList.contains("toggleRule")) {
            toggleRule(target.dataset.id, target.dataset.enabled === "true");
          }
          if (target.classList.contains("deleteRule")) {
            deleteRule(target.dataset.id);
          }
        });
        loadData();
        loadRules();
      </script>
    </body>
    </html>
    """
  end
end

# MiniAstarte (local demo)

A tiny, local-only IoT platform inspired by Astarte. Single-tenant, MQTT + HTTP ingest, SQLite storage.

## Tech stack
- Elixir
- Plug + Cowboy (HTTP)
- Ecto + SQLite
- Tortoise (MQTT client)
- Phoenix PubSub (local events)

## Inspiration
This project is a small-scale learning experiment inspired by the open-source Astarte platform.
It is not affiliated with or endorsed by Astarte, and is intended for local testing and curiosity.

## Features
- Device registry with token auth
- MQTT ingest on `devices/<device_id>/data`
- HTTP ingest on `/api/ingest`
- SQLite storage for devices, measurements, alerts
- Simple rules engine (threshold alerts)

## Requirements (Windows)
- Erlang/OTP + Elixir
- SQLite (bundled via `ecto_sqlite3`)
- Mosquitto (MQTT broker)

## Setup
```powershell
cd C:\Users\roves\OneDrive\Documenti\GitHub\mini_astarte
mix deps.get
mix ecto.create
mix ecto.migrate
```

## Run
```powershell
mix run --no-halt
```

## Register a device
```powershell
curl -Method Post http://localhost:4000/api/devices -Body '{"id":"dev-1","name":"Boiler"}' -ContentType 'application/json'
```

## HTTP ingest
```powershell
curl -Method Post http://localhost:4000/api/ingest -Body '{"device_id":"dev-1","token":"<TOKEN>","key":"temp","value":42.2}' -ContentType 'application/json'
```

You can also pass the token as a header:
```powershell
curl -Method Post http://localhost:4000/api/ingest -Body '{"device_id":"dev-1","key":"temp","value":42.2}' -ContentType 'application/json' -Headers @{ "x-device-token" = "<TOKEN>" }
```

## MQTT ingest
```powershell
mosquitto_pub -t devices/dev-1/data -m '{"token":"<TOKEN>","key":"temp","value":42.2}'
```

You can also embed the token in the topic:
```powershell
mosquitto_pub -t devices/dev-1/data/<TOKEN> -m '{"key":"temp","value":42.2}'
```

## Read data
```powershell
Invoke-RestMethod http://localhost:4000/api/measurements
Invoke-RestMethod http://localhost:4000/api/alerts
Invoke-RestMethod http://localhost:4000/api/state
Invoke-RestMethod "http://localhost:4000/api/measurements?device_id=dev-1&limit=50&offset=0"
Invoke-RestMethod "http://localhost:4000/api/alerts?from=2026-01-19T16:00:00Z&to=2026-01-19T18:00:00Z"
```

## Export CSV
```powershell
Invoke-WebRequest "http://localhost:4000/api/export/measurements.csv?device_id=dev-1" -OutFile measurements.csv
Invoke-WebRequest "http://localhost:4000/api/export/alerts.csv" -OutFile alerts.csv
Invoke-WebRequest "http://localhost:4000/api/export/state.csv" -OutFile state.csv
```

## Rules API
```powershell
Invoke-RestMethod -Method Post http://localhost:4000/api/rules -Body '{"key":"temp","op":"gt","value":30.0,"enabled":true}' -ContentType 'application/json' -Headers @{ "x-admin-token" = "change-me" }
Invoke-RestMethod http://localhost:4000/api/rules
Invoke-RestMethod -Method Put http://localhost:4000/api/rules/<RULE_ID> -Body '{"enabled":false}' -ContentType 'application/json' -Headers @{ "x-admin-token" = "change-me" }
Invoke-RestMethod -Method Delete http://localhost:4000/api/rules/<RULE_ID> -Headers @{ "x-admin-token" = "change-me" }
```

## Dashboard
Open `http://localhost:4000/dashboard` in your browser.

## Realtime
The dashboard connects to the WebSocket at `/ws` for live measurements and alerts.

## Device scripts
Edit the token in `scripts/device_http.ps1` or `scripts/device_mqtt.ps1` and run them.

## Notes
- Rules are in `config/config.exs` under `:rules`.
- Default HTTP port is 4000.
- Default MQTT broker is localhost:1883.
 - Set `admin_token` in `config/config.exs` to enable rules CRUD.

## Tests
```powershell
mix test
```

$deviceId = "dev-1"
$token = "<TOKEN>"
$payload = @{
  device_id = $deviceId
  token = $token
  key = "temp"
  value = 42.2
} | ConvertTo-Json -Compress

Invoke-RestMethod -Method Post "http://localhost:4000/api/ingest" `
  -Body $payload -ContentType "application/json"

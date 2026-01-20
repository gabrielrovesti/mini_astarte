$deviceId = "dev-1"
$token = "<TOKEN>"
$payload = @{ token = $token; key = "temp"; value = 42.2 } | ConvertTo-Json -Compress

mosquitto_pub -t "devices/$deviceId/data" -m $payload

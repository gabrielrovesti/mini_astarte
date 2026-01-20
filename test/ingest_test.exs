defmodule MiniAstarte.IngestTest do
  use ExUnit.Case, async: false

  alias MiniAstarte.{Devices, Ingest, Repo}
  alias MiniAstarte.Schemas.{Device, DeviceState, Measurement}

  setup do
    Repo.delete_all(DeviceState)
    Repo.delete_all(Measurement)
    Repo.delete_all(Device)
    :ok
  end

  test "ingest creates measurement and device state" do
    {:ok, device} = Devices.register_device("dev-1", "Boiler")
    {:ok, measurement} = Ingest.ingest_http("dev-1", device.token, "temp", 42.0, nil)

    assert measurement.device_id == "dev-1"
    assert measurement.key == "temp"

    state = Repo.get_by(DeviceState, device_id: "dev-1", key: "temp")
    assert state.value == 42.0
  end
end

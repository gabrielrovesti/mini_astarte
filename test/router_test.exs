defmodule MiniAstarteWeb.RouterTest do
  use ExUnit.Case, async: false
  use Plug.Test

  alias MiniAstarte.Repo
  alias MiniAstarte.Schemas.{AlertRule, Device, DeviceState, Measurement}
  alias MiniAstarteWeb.Router

  setup do
    Repo.delete_all(AlertRule)
    Repo.delete_all(DeviceState)
    Repo.delete_all(Measurement)
    Repo.delete_all(Device)
    :ok
  end

  test "register device" do
    conn =
      conn(:post, "/api/devices", Jason.encode!(%{id: "dev-1", name: "Boiler"}))
      |> put_req_header("content-type", "application/json")
      |> Router.call([])

    assert conn.status == 201
  end

  test "create rule requires admin token" do
    conn =
      conn(:post, "/api/rules", Jason.encode!(%{key: "temp", op: "gt", value: 30.0}))
      |> put_req_header("content-type", "application/json")
      |> Router.call([])

    assert conn.status == 401

    conn =
      conn(:post, "/api/rules", Jason.encode!(%{key: "temp", op: "gt", value: 30.0}))
      |> put_req_header("content-type", "application/json")
      |> put_req_header("x-admin-token", "test-token")
      |> Router.call([])

    assert conn.status == 201
  end
end

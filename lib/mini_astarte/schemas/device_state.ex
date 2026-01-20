defmodule MiniAstarte.Schemas.DeviceState do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :string
  schema "device_states" do
    field :device_id, :string
    field :key, :string
    field :value, :float
    field :ts, :utc_datetime_usec

    timestamps()
  end

  def changeset(state, attrs) do
    state
    |> cast(attrs, [:device_id, :key, :value, :ts])
    |> validate_required([:device_id, :key, :value, :ts])
  end
end

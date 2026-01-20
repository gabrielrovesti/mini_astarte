defmodule MiniAstarte.Schemas.Alert do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :string
  schema "alerts" do
    field :device_id, :string
    field :rule, :string
    field :payload, :map
    field :ts, :utc_datetime_usec

    timestamps()
  end

  def changeset(alert, attrs) do
    alert
    |> cast(attrs, [:device_id, :rule, :payload, :ts])
    |> validate_required([:device_id, :rule, :payload, :ts])
  end
end

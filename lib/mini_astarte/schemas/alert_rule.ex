defmodule MiniAstarte.Schemas.AlertRule do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :string
  schema "alert_rules" do
    field :device_id, :string
    field :key, :string
    field :op, :string
    field :value, :float
    field :enabled, :boolean, default: true

    timestamps()
  end

  def changeset(rule, attrs) do
    rule
    |> cast(attrs, [:device_id, :key, :op, :value, :enabled])
    |> validate_required([:key, :op, :value])
    |> validate_inclusion(:op, ["gt", "gte", "lt", "lte", "eq"])
  end
end

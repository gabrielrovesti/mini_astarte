defmodule MiniAstarte.Schemas.Device do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :string, autogenerate: false}
  schema "devices" do
    field :name, :string
    field :token, :string

    timestamps()
  end

  def changeset(device, attrs) do
    device
    |> cast(attrs, [:id, :name, :token])
    |> validate_required([:id, :token])
  end
end

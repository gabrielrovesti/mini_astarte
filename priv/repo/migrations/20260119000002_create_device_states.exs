defmodule MiniAstarte.Repo.Migrations.CreateDeviceStates do
  use Ecto.Migration

  def change do
    create table(:device_states, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :device_id, :string, null: false
      add :key, :string, null: false
      add :value, :float, null: false
      add :ts, :utc_datetime_usec, null: false

      timestamps()
    end

    create unique_index(:device_states, [:device_id, :key])
  end
end

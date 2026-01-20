defmodule MiniAstarte.Repo.Migrations.CreateTables do
  use Ecto.Migration

  def change do
    create table(:devices, primary_key: false) do
      add :id, :string, primary_key: true
      add :name, :string
      add :token, :string, null: false

      timestamps()
    end

    create table(:measurements, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :device_id, references(:devices, type: :string, on_delete: :delete_all), null: false
      add :key, :string, null: false
      add :value, :float, null: false
      add :ts, :utc_datetime_usec, null: false

      timestamps()
    end

    create table(:alerts, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :device_id, references(:devices, type: :string, on_delete: :delete_all), null: false
      add :rule, :string, null: false
      add :payload, :map, null: false
      add :ts, :utc_datetime_usec, null: false

      timestamps()
    end
  end
end

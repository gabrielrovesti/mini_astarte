defmodule MiniAstarte.Repo.Migrations.CreateAlertRules do
  use Ecto.Migration

  def change do
    create table(:alert_rules, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :device_id, :string
      add :key, :string, null: false
      add :op, :string, null: false
      add :value, :float, null: false
      add :enabled, :boolean, null: false, default: true

      timestamps()
    end

    create index(:alert_rules, [:device_id])
    create index(:alert_rules, [:key])
  end
end

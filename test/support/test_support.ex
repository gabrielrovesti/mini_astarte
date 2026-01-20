defmodule MiniAstarte.TestSupport do
  def setup_db do
    db_path = Path.join(["priv", "mini_astarte_test.db"])
    File.rm(db_path)

    {:ok, _} = Application.ensure_all_started(:ecto_sql)
    {:ok, _} = MiniAstarte.Repo.start_link()

    migrations_path = Application.app_dir(:mini_astarte, "priv/repo/migrations")

    Ecto.Migrator.with_repo(MiniAstarte.Repo, fn repo ->
      Ecto.Migrator.run(repo, migrations_path, :up, all: true)
    end)
  end
end

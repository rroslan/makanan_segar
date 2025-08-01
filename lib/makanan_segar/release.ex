defmodule MakananSegar.Release do
  @app :makanan_segar

  def migrate do
    Application.load(@app)

    for repo <- Application.fetch_env!(@app, :ecto_repos) do
      {:ok, _pid} = repo.start_link(pool_size: 2)
      Ecto.Migrator.run(repo, migrations_path(repo), :up, all: true)
    end
  end

  defp migrations_path(repo) do
    priv_dir = Application.app_dir(@app, "priv")
    Path.join([priv_dir, repo |> Module.split() |> List.last() |> Macro.underscore(), "migrations"])
  end
end

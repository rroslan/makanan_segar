ExUnit.start()
Ecto.Adapters.SQL.Sandbox.mode(MakananSegar.Repo, :manual)

# Configure Oban for testing
Application.put_env(:makanan_segar, Oban, testing: :inline)

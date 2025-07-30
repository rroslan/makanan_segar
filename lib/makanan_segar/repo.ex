defmodule MakananSegar.Repo do
  use Ecto.Repo,
    otp_app: :makanan_segar,
    adapter: Ecto.Adapters.Postgres
end

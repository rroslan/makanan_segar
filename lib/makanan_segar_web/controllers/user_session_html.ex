defmodule MakananSegarWeb.UserSessionHTML do
  use MakananSegarWeb, :html

  embed_templates "user_session_html/*"

  defp local_mail_adapter? do
    Application.get_env(:makanan_segar, MakananSegar.Mailer)[:adapter] == Swoosh.Adapters.Local
  end
end

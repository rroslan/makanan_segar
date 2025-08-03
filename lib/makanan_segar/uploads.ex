defmodule MakananSegar.Uploads do
  @moduledoc """
  A helper module for handling file uploads.
  """

  @doc """
  Stores an uploaded file from a form into the persistent uploads directory.

  It takes a `Plug.Upload` struct, generates a unique filename, copies the
  temporary file to the final destination, and returns the public-facing
  URL path to be stored in the database.
  """
  def store(%Plug.Upload{} = upload) do
    uploads_dir = uploads_dir()
    filename = "#{Ecto.UUID.generate()}#{Path.extname(upload.filename)}"
    dest_path = Path.join(uploads_dir, filename)

    case File.cp(upload.path, dest_path) do
      :ok ->
        # This is the public path that will be stored in the database
        # and used in `<img>` tags.
        {:ok, "/uploads/#{filename}"}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp uploads_dir do
    Application.fetch_env!(:makanan_segar, :uploads_dir)
  end
end
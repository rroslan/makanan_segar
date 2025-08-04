defmodule MakananSegar.Uploads do
  @moduledoc """
  A helper module for handling file uploads.
  """

  require Logger

  @allowed_extensions [".jpg", ".jpeg", ".png", ".webp"]
  # 5MB
  @max_file_size 5_000_000

  @doc """
  Stores an uploaded file from a form into the persistent uploads directory.

  It takes a `Plug.Upload` struct, generates a unique filename, copies the
  temporary file to the final destination, and returns the public-facing
  URL path to be stored in the database.
  """
  def store(%Plug.Upload{} = upload, subdirectory \\ nil) do
    with :ok <- validate_file(upload),
         {:ok, dest_path, public_path} <- prepare_file_paths(upload, subdirectory),
         :ok <- ensure_uploads_dir_exists(subdirectory),
         :ok <- copy_file(upload.path, dest_path) do
      Logger.info("File uploaded successfully: #{public_path}")
      {:ok, public_path}
    else
      {:error, reason} = error ->
        Logger.error("File upload failed: #{inspect(reason)}")
        error
    end
  end

  defp validate_file(%Plug.Upload{filename: filename} = upload) do
    extension = Path.extname(filename) |> String.downcase()

    cond do
      extension not in @allowed_extensions ->
        {:error, :invalid_file_type}

      File.stat!(upload.path).size > @max_file_size ->
        {:error, :file_too_large}

      true ->
        :ok
    end
  end

  defp prepare_file_paths(%Plug.Upload{filename: filename}, subdirectory) do
    uploads_dir = uploads_dir()
    extension = Path.extname(filename)
    unique_filename = "#{Ecto.UUID.generate()}#{extension}"

    {dest_path, public_path} =
      case subdirectory do
        nil ->
          {
            Path.join(uploads_dir, unique_filename),
            "/uploads/#{unique_filename}"
          }

        subdir ->
          {
            Path.join([uploads_dir, subdir, unique_filename]),
            "/uploads/#{subdir}/#{unique_filename}"
          }
      end

    {:ok, dest_path, public_path}
  end

  defp ensure_uploads_dir_exists(subdirectory) do
    base_uploads_dir = uploads_dir()

    target_dir =
      case subdirectory do
        nil -> base_uploads_dir
        subdir -> Path.join(base_uploads_dir, subdir)
      end

    case File.mkdir_p(target_dir) do
      :ok -> :ok
      {:error, reason} -> {:error, reason}
    end
  end

  defp copy_file(source_path, dest_path) do
    case File.cp(source_path, dest_path) do
      :ok -> :ok
      {:error, reason} -> {:error, reason}
    end
  end

  defp uploads_dir do
    Application.fetch_env!(:makanan_segar, :uploads_dir)
  end
end

defmodule MakananSegarWeb.TestUploadLive do
  use MakananSegarWeb, :live_view

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-4xl mx-auto p-8">
      <h1 class="text-3xl font-bold mb-6">Upload Debug Test</h1>
      
    <!-- Debug Info -->
      <div class="mb-6 p-4 bg-blue-50 rounded">
        <h2 class="text-lg font-semibold mb-2">Debug Information</h2>
        <p><strong>LiveView Connected:</strong> {if connected?(@socket), do: "YES", else: "NO"}</p>
        <p><strong>Upload Entries:</strong> {length(@uploads.test_file.entries)}</p>
        <p><strong>Last Action:</strong> {@debug_info}</p>
      </div>

      <.form for={@form} id="test-upload-form" phx-change="validate" phx-submit="save" multipart>
        <div class="space-y-4">
          <div>
            <label class="block text-lg font-medium mb-2">Select a File</label>
            <.live_file_input
              upload={@uploads.test_file}
              class="file-input file-input-bordered w-full text-lg p-3"
            />
            <div class="text-sm text-gray-600 mt-2">JPG, PNG, WebP (max 5MB)</div>
          </div>
          
    <!-- Show upload config -->
          <div class="bg-gray-100 p-4 rounded">
            <h3 class="font-semibold">Upload Configuration:</h3>
            <div class="grid grid-cols-2 gap-2 text-sm">
              <p><strong>Entries:</strong> {length(@uploads.test_file.entries)}</p>
              <p><strong>Max entries:</strong> {@uploads.test_file.max_entries}</p>
              <p><strong>Max file size:</strong> {format_size(@uploads.test_file.max_file_size)}</p>
              <p><strong>Accept:</strong> {Enum.join(@uploads.test_file.accept, ", ")}</p>
              <p>
                <strong>Auto upload:</strong> {if @uploads.test_file.auto_upload?,
                  do: "YES",
                  else: "NO"}
              </p>
              <p><strong>Ref:</strong> {@uploads.test_file.ref}</p>
            </div>
          </div>
          
    <!-- Show file selection status -->
          <div class="border-2 border-dashed border-gray-300 p-6 rounded text-center">
            <%= if @uploads.test_file.entries == [] do %>
              <p class="text-xl text-gray-500">No files selected</p>
              <p class="text-sm text-gray-400 mt-1">
                The file input above should allow you to select files
              </p>
            <% else %>
              <p class="text-xl text-green-600 font-semibold">✓ Files Selected!</p>
            <% end %>
          </div>
          
    <!-- Show entries -->
          <%= if @uploads.test_file.entries != [] do %>
            <div class="bg-green-50 border-l-4 border-green-400 p-4">
              <h3 class="text-lg font-semibold text-green-800 mb-3">Selected Files:</h3>
              <%= for entry <- @uploads.test_file.entries do %>
                <div class="bg-white p-3 rounded shadow-sm mb-3">
                  <div class="grid grid-cols-2 gap-2 text-sm mb-2">
                    <p><strong>Name:</strong> {entry.client_name}</p>
                    <p><strong>Size:</strong> {format_size(entry.client_size)}</p>
                    <p><strong>Type:</strong> {entry.client_type}</p>
                    <p><strong>Progress:</strong> {entry.progress}%</p>
                    <p><strong>Done:</strong> {if entry.done?, do: "YES", else: "NO"}</p>
                    <p><strong>Valid:</strong> {if entry.valid?, do: "YES", else: "NO"}</p>
                  </div>
                  
    <!-- Preview if image -->
                  <%= if String.starts_with?(entry.client_type, "image/") do %>
                    <div class="mt-2">
                      <p class="text-sm font-medium mb-1">Preview:</p>
                      <.live_img_preview entry={entry} class="w-32 h-32 object-cover border rounded" />
                    </div>
                  <% end %>

                  <button
                    type="button"
                    phx-click="cancel-upload"
                    phx-value-ref={entry.ref}
                    class="btn btn-sm btn-error mt-2"
                  >
                    Remove File
                  </button>
                </div>
              <% end %>
            </div>
          <% end %>
          
    <!-- Show upload errors -->
          <%= for err <- upload_errors(@uploads.test_file) do %>
            <div class="alert alert-error">
              Upload error: {inspect(err)}
            </div>
          <% end %>
          
    <!-- Show entry errors -->
          <%= for entry <- @uploads.test_file.entries do %>
            <%= for err <- upload_errors(@uploads.test_file, entry) do %>
              <div class="alert alert-error">
                {entry.client_name}: {inspect(err)}
              </div>
            <% end %>
          <% end %>

          <div class="flex gap-4">
            <button type="submit" class="btn btn-primary">
              Test Upload
            </button>
            <button type="button" phx-click="clear-all" class="btn btn-secondary">
              Clear All
            </button>
          </div>
        </div>
      </.form>
      
    <!-- Results -->
      <%= if @result do %>
        <div class="mt-8 p-4 bg-blue-100 rounded">
          <h3 class="font-semibold">Last Upload Result:</h3>
          <pre class="mt-2 text-sm"><%= @result %></pre>
        </div>
      <% end %>
    </div>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    require Logger
    Logger.info("TEST UPLOAD - Mount started")

    socket =
      socket
      |> assign(:form, to_form(%{}))
      |> assign(:result, nil)
      |> assign(:debug_info, "Page loaded")
      |> allow_upload(:test_file,
        accept: ~w(.jpg .jpeg .png .webp),
        max_entries: 3,
        max_file_size: 5_000_000,
        auto_upload: false,
        progress: &handle_progress/3
      )

    Logger.info("TEST UPLOAD - Mount completed")
    Logger.info("TEST UPLOAD - Socket connected: #{connected?(socket)}")

    Logger.info(
      "TEST UPLOAD - Upload entries: #{length(socket.assigns.uploads.test_file.entries)}"
    )

    {:ok, socket}
  end

  @impl true
  def handle_event("validate", params, socket) do
    require Logger
    Logger.info("TEST UPLOAD - Validate called with params: #{inspect(params)}")

    entries_count = length(socket.assigns.uploads.test_file.entries)
    Logger.info("TEST UPLOAD - Current entries: #{entries_count}")

    debug_info = "File selection detected - #{entries_count} entries"

    for entry <- socket.assigns.uploads.test_file.entries do
      Logger.info(
        "TEST UPLOAD - Entry: #{entry.client_name}, size: #{entry.client_size}, type: #{entry.client_type}, progress: #{entry.progress}%"
      )
    end

    upload_errors = upload_errors(socket.assigns.uploads.test_file)

    if upload_errors != [] do
      Logger.error("TEST UPLOAD - Upload errors: #{inspect(upload_errors)}")
    end

    {:noreply, assign(socket, :debug_info, debug_info)}
  end

  @impl true
  def handle_event("save", _params, socket) do
    require Logger
    Logger.info("TEST UPLOAD - Save called")

    Logger.info(
      "TEST UPLOAD - Entries to consume: #{length(socket.assigns.uploads.test_file.entries)}"
    )

    uploaded_files =
      consume_uploaded_entries(socket, :test_file, fn %{path: path}, entry ->
        Logger.info("TEST UPLOAD - Consuming: #{entry.client_name} from #{path}")

        # Copy to our uploads directory for testing
        dest_filename = "test_#{System.unique_integer()}_#{entry.client_name}"

        dest_path =
          Path.join([
            Application.fetch_env!(:makanan_segar, :uploads_dir),
            dest_filename
          ])

        case File.cp(path, dest_path) do
          :ok ->
            Logger.info("TEST UPLOAD - Copied to: #{dest_path}")

            %{
              original_name: entry.client_name,
              size: entry.client_size,
              type: entry.client_type,
              saved_path: dest_path,
              public_url: "/uploads/#{dest_filename}"
            }

          {:error, reason} ->
            Logger.error("TEST UPLOAD - Copy failed: #{inspect(reason)}")
            %{error: reason}
        end
      end)

    result = %{
      uploaded_count: length(uploaded_files),
      files: uploaded_files,
      timestamp: DateTime.utc_now()
    }

    Logger.info("TEST UPLOAD - Final result: #{inspect(result)}")

    {:noreply,
     socket
     |> assign(:result, inspect(result, pretty: true))
     |> put_flash(:info, "Uploaded #{length(uploaded_files)} file(s) successfully!")}
  end

  @impl true
  def handle_event("cancel-upload", %{"ref" => ref}, socket) do
    require Logger
    Logger.info("TEST UPLOAD - Canceling upload ref: #{ref}")

    {:noreply, cancel_upload(socket, :test_file, ref)}
  end

  @impl true
  def handle_event("clear-all", _params, socket) do
    require Logger
    Logger.info("TEST UPLOAD - Clearing all uploads")

    # Cancel all uploads
    socket =
      Enum.reduce(socket.assigns.uploads.test_file.entries, socket, fn entry, acc ->
        cancel_upload(acc, :test_file, entry.ref)
      end)

    {:noreply,
     socket
     |> assign(:result, nil)
     |> put_flash(:info, "Cleared all uploads")}
  end

  defp handle_progress(:test_file, entry, socket) do
    require Logger

    Logger.info(
      "TEST UPLOAD - Progress: #{entry.client_name} - #{entry.progress}% (done: #{entry.done?})"
    )

    if entry.done? do
      Logger.info("TEST UPLOAD - Upload completed: #{entry.client_name}")
    end

    {:noreply, socket}
  end

  defp format_size(size) when size < 1024, do: "#{size} B"
  defp format_size(size) when size < 1024 * 1024, do: "#{Float.round(size / 1024, 1)} KB"
  defp format_size(size), do: "#{Float.round(size / (1024 * 1024), 1)} MB"
end

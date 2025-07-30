defmodule MakananSegarWeb.Vendor.ProductLive.Form do
  use MakananSegarWeb, :live_view
  on_mount {MakananSegarWeb.UserAuthHooks, :require_complete_vendor_profile}

  alias MakananSegar.Products
  alias MakananSegar.Products.Product

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        {@page_title}
        <:subtitle>Use this form to manage product records in your database.</:subtitle>
        <:actions>
          <.link navigate={return_path(@current_scope, @return_to, @product)} class="btn btn-ghost">
            <.icon name="hero-arrow-left" class="w-4 h-4 mr-2" /> Back
          </.link>
        </:actions>
      </.header>

      <.form for={@form} id="product-form" phx-change="validate" phx-submit="save">
        <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
          <!-- Left Column -->
          <div class="space-y-4">
            <.input
              field={@form[:name]}
              type="text"
              label="Product Name"
              placeholder="Fresh Atlantic Salmon"
            />

            <.input
              field={@form[:description]}
              type="textarea"
              label="Description"
              placeholder="Describe your product..."
              rows="4"
            />

            <.input
              field={@form[:category]}
              type="select"
              label="Category"
              options={[
                {"Fish", "fish"},
                {"Vegetables", "vegetables"},
                {"Fruits", "fruits"}
              ]}
            />

            <.input
              field={@form[:price]}
              type="number"
              label="Price (RM)"
              step="0.01"
              min="0"
              placeholder="29.90"
            />

            <.input
              field={@form[:expires_at]}
              type="datetime-local"
              label="Expires at"
              min={
                DateTime.now!("Asia/Kuala_Lumpur") |> DateTime.to_naive() |> NaiveDateTime.to_string()
              }
            />

            <.input field={@form[:is_active]} type="checkbox" label="Make product active immediately" />
          </div>
          
    <!-- Right Column - Image Upload -->
          <div>
            <div class="form-control">
              <label class="label">
                <span class="label-text">Product Image</span>
              </label>
              
    <!-- Current Image Display -->
              <%= if @product.image do %>
                <div class="mb-4">
                  <h5 class="font-medium mb-2">Current Image:</h5>
                  <div class="relative inline-block">
                    <img
                      src={@product.image}
                      alt="Current product image"
                      class="w-64 h-48 object-cover rounded-lg border-2 border-gray-200"
                    />
                    <button
                      type="button"
                      phx-click="remove-current-image"
                      class="absolute top-2 right-2 btn btn-sm btn-circle btn-error"
                      title="Remove current image"
                    >
                      <.icon name="hero-x-mark" class="w-4 h-4" />
                    </button>
                  </div>
                </div>
              <% end %>
              
    <!-- File Input -->
              <.live_file_input
                upload={@uploads.product_image}
                class="file-input file-input-bordered w-full"
              />
              <div class="label">
                <span class="label-text-alt">JPG, PNG or WEBP (max 5MB)</span>
              </div>
              
    <!-- Drop Zone -->
              <div
                class="border-2 border-dashed border-gray-300 rounded-lg p-6 text-center hover:border-primary transition-colors mt-4"
                phx-drop-target={@uploads.product_image.ref}
              >
                <.icon name="hero-photo" class="w-12 h-12 mx-auto text-gray-400 mb-2" />
                <p class="text-sm text-gray-600">
                  Drag and drop your image here, or click to browse
                </p>
              </div>
              
    <!-- Upload Preview -->
              <%= if @uploads.product_image.entries != [] do %>
                <div class="mt-4">
                  <h5 class="font-medium mb-2">New Image Preview:</h5>
                  <%= for entry <- @uploads.product_image.entries do %>
                    <div class="relative inline-block">
                      <!-- Image Preview -->
                      <.live_img_preview
                        entry={entry}
                        class="w-64 h-48 object-cover rounded-lg border-2 border-gray-200"
                      />
                      
    <!-- Upload Progress -->
                      <%= if entry.progress > 0 and entry.progress < 100 do %>
                        <div class="absolute inset-0 bg-black bg-opacity-50 rounded-lg flex items-center justify-center">
                          <div
                            class="radial-progress text-primary"
                            style={"--value:#{entry.progress}"}
                          >
                            {entry.progress}%
                          </div>
                        </div>
                      <% end %>
                      
    <!-- Remove Button -->
                      <button
                        type="button"
                        phx-click="cancel-upload"
                        phx-value-ref={entry.ref}
                        class="absolute top-2 right-2 btn btn-sm btn-circle btn-error"
                      >
                        <.icon name="hero-x-mark" class="w-4 h-4" />
                      </button>
                    </div>
                  <% end %>
                </div>
              <% end %>
              
    <!-- Upload Errors -->
              <%= for err <- upload_errors(@uploads.product_image) do %>
                <div class="alert alert-error mt-2">
                  <.icon name="hero-exclamation-triangle" class="w-4 h-4" />
                  <span>{error_to_string(err)}</span>
                </div>
              <% end %>
              
    <!-- Entry Errors -->
              <%= for entry <- @uploads.product_image.entries do %>
                <%= for err <- upload_errors(@uploads.product_image, entry) do %>
                  <div class="alert alert-error mt-2">
                    <.icon name="hero-exclamation-triangle" class="w-4 h-4" />
                    <span>{entry.client_name}: {error_to_string(err)}</span>
                  </div>
                <% end %>
              <% end %>
              
    <!-- Hidden field for existing image -->
              <input type="hidden" name="product[image]" value={@form[:image].value} />
            </div>
          </div>
        </div>

        <div class="divider"></div>

        <footer class="flex justify-end gap-4">
          <.link navigate={return_path(@current_scope, @return_to, @product)} class="btn btn-ghost">
            Cancel
          </.link>
          <.button phx-disable-with="Saving..." variant="primary">
            <.icon name="hero-check" class="w-4 h-4 mr-2" /> Save Product
          </.button>
        </footer>
      </.form>
    </Layouts.app>
    """
  end

  @impl true
  def mount(params, _session, socket) do
    {:ok,
     socket
     |> assign(:return_to, return_to(params["return_to"]))
     |> allow_upload(:product_image,
       accept: ~w(.jpg .jpeg .png .webp),
       max_entries: 1,
       max_file_size: 5_000_000,
       auto_upload: false
     )
     |> apply_action(socket.assigns.live_action, params)}
  end

  defp return_to("show"), do: "show"
  defp return_to(_), do: "index"

  defp apply_action(socket, :edit, %{"id" => id}) do
    product = Products.get_product!(socket.assigns.current_scope, id)

    socket
    |> assign(:page_title, "Edit Product")
    |> assign(:product, product)
    |> assign(:form, to_form(Products.change_product(socket.assigns.current_scope, product)))
  end

  defp apply_action(socket, :new, _params) do
    product = %Product{user_id: socket.assigns.current_scope.user.id}

    socket
    |> assign(:page_title, "New Product")
    |> assign(:product, product)
    |> assign(:form, to_form(Products.change_product(socket.assigns.current_scope, product)))
  end

  @impl true
  def handle_event("validate", %{"product" => product_params}, socket) do
    changeset =
      Products.change_product(
        socket.assigns.current_scope,
        socket.assigns.product,
        product_params
      )

    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"product" => product_params}, socket) do
    # Handle image upload
    uploaded_files =
      consume_uploaded_entries(socket, :product_image, fn %{path: path}, entry ->
        upload_dir = "priv/static/uploads/products"
        File.mkdir_p!(upload_dir)

        ext = Path.extname(entry.client_name) |> String.downcase() |> String.trim_leading(".")
        filename = "#{DateTime.utc_now() |> DateTime.to_unix()}_#{entry.uuid}.#{ext}"
        dest = Path.join(upload_dir, filename)

        File.cp!(path, dest)
        {:ok, "/uploads/products/#{filename}"}
      end)

    # Add uploaded image URL to params if present
    product_params =
      case uploaded_files do
        [url | _] -> Map.put(product_params, "image", url)
        _ -> product_params
      end

    save_product(socket, socket.assigns.live_action, product_params)
  end

  def handle_event("cancel-upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :product_image, ref)}
  end

  def handle_event("remove-current-image", _, socket) do
    changeset =
      Products.change_product(
        socket.assigns.current_scope,
        socket.assigns.product,
        %{"image" => nil}
      )

    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  defp save_product(socket, :edit, product_params) do
    case Products.update_product(
           socket.assigns.current_scope,
           socket.assigns.product,
           product_params
         ) do
      {:ok, product} ->
        {:noreply,
         socket
         |> put_flash(:info, "Product updated successfully")
         |> push_navigate(
           to: return_path(socket.assigns.current_scope, socket.assigns.return_to, product)
         )}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_product(socket, :new, product_params) do
    case Products.create_product(socket.assigns.current_scope, product_params) do
      {:ok, product} ->
        {:noreply,
         socket
         |> put_flash(:info, "Product created successfully")
         |> push_navigate(
           to: return_path(socket.assigns.current_scope, socket.assigns.return_to, product)
         )}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp return_path(_scope, "show", product), do: ~p"/vendor/products/#{product}"
  defp return_path(_scope, _return_to, _product), do: ~p"/vendor/products"

  defp error_to_string(:too_large), do: "File is too large (max 5MB)"
  defp error_to_string(:not_accepted), do: "Invalid file type. Please upload JPG, PNG, or WEBP"
  defp error_to_string(:too_many_files), do: "You can only upload one image"
  defp error_to_string(err), do: Phoenix.Naming.humanize(err)
end

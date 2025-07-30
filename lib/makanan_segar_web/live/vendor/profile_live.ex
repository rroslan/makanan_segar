defmodule MakananSegarWeb.Vendor.ProfileLive do
  use MakananSegarWeb, :live_view
  on_mount {MakananSegarWeb.UserAuthHooks, :require_vendor_user}

  alias MakananSegar.Accounts
  alias MakananSegar.Products

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        Vendor Profile
        <:subtitle>Manage your vendor profile information</:subtitle>
      </.header>

      <div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
        <!-- Profile Image Section -->
        <div class="lg:col-span-1">
          <div class="card bg-base-100 shadow-xl">
            <div class="card-body items-center text-center">
              <div class="avatar">
                <div class="w-32 rounded-full">
                  <%= if @user.profile_image do %>
                    <img
                      src={@user.profile_image}
                      alt="Profile Image"
                      onerror="this.onerror=null; this.style.display='none'; this.nextElementSibling.style.display='flex';"
                    />
                    <div
                      class="bg-neutral text-neutral-content rounded-full w-32 h-32 flex items-center justify-center"
                      style="display:none;"
                    >
                      <span class="text-3xl font-bold">
                        {String.first(@user.business_name || @user.name || @user.email)
                        |> String.upcase()}
                      </span>
                    </div>
                  <% else %>
                    <div class="bg-neutral text-neutral-content rounded-full w-32 h-32 flex items-center justify-center">
                      <span class="text-3xl font-bold">
                        {String.first(@user.business_name || @user.name || @user.email)
                        |> String.upcase()}
                      </span>
                    </div>
                  <% end %>
                </div>
              </div>
              <h2 class="card-title">{@user.business_name || @user.name || "Vendor"}</h2>
              <p class="text-sm opacity-70">{@user.email}</p>
              <%= if @user.phone do %>
                <p class="text-sm opacity-70">📞 {@user.phone}</p>
              <% end %>
              <div class="badge badge-primary">{@user.business_type || "Vendor"}</div>
              <%= if @user.website do %>
                <a
                  href={@user.website}
                  target="_blank"
                  class="btn btn-sm btn-outline btn-primary mt-2"
                >
                  🌐 Website
                </a>
              <% end %>
            </div>
          </div>
          
    <!-- Business Information Card -->
          <%= if @user.business_name || @user.business_description || @user.business_hours do %>
            <div class="card bg-base-100 shadow-xl mt-4">
              <div class="card-body">
                <h3 class="card-title text-base">Business Info</h3>
                <%= if @user.business_description do %>
                  <p class="text-sm opacity-80">{@user.business_description}</p>
                <% end %>
                <%= if @user.business_hours do %>
                  <div class="mt-2">
                    <span class="font-semibold text-sm">Hours:</span>
                    <p class="text-sm opacity-80">{@user.business_hours}</p>
                  </div>
                <% end %>
                <%= if @user.business_registration_number do %>
                  <div class="mt-2">
                    <span class="font-semibold text-sm">Reg. No:</span>
                    <p class="text-sm opacity-80">{@user.business_registration_number}</p>
                  </div>
                <% end %>
              </div>
            </div>
          <% end %>
        </div>
        
    <!-- Profile Form Section -->
        <div class="lg:col-span-2">
          <div class="card bg-base-100 shadow-xl">
            <div class="card-body">
              <.form for={@form} id="profile-form" phx-submit="save" phx-change="validate" multipart>
                <h3 class="text-lg font-semibold mb-4">Personal Information</h3>

                <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                  <.input
                    field={@form[:name]}
                    type="text"
                    label="Full Name *"
                    placeholder="Enter your full name"
                    required
                  />

                  <div>
                    <.input
                      field={@form[:phone]}
                      type="tel"
                      label="Phone Number *"
                      placeholder="+60123456789"
                      required
                    />
                    <p class="text-xs text-base-content/70 mt-1">
                      Customers will contact you through this number
                    </p>
                  </div>
                </div>

                <div class="mt-4">
                  <.input
                    field={@form[:address]}
                    type="textarea"
                    label="Address * (Malaysia only)"
                    placeholder="Street, City, State, Postcode (e.g., 123 Jalan ABC, Petaling Jaya, Selangor, 47301)"
                    rows="3"
                    required
                  />
                  <p class="text-xs text-base-content/70 mt-1">
                    Your business location for pickup/delivery arrangements
                  </p>
                </div>

                <h3 class="text-lg font-semibold mb-4 mt-6">Business Information</h3>
                <div class="alert alert-info mb-4">
                  <.icon name="hero-information-circle" class="w-5 h-5" />
                  <div>
                    <p class="text-sm font-semibold">Required fields are marked with *</p>
                    <p class="text-sm">
                      Complete all required fields to start selling. Optional fields help build trust with customers.
                    </p>
                  </div>
                </div>

                <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                  <div>
                    <.input
                      field={@form[:business_name]}
                      type="text"
                      label="Business Name *"
                      placeholder="Your shop or business name"
                      required
                    />
                    <p class="text-xs text-base-content/70 mt-1">
                      This is how customers will know your shop
                    </p>
                  </div>

                  <.input
                    field={@form[:business_type]}
                    type="select"
                    label="Business Type"
                    options={[
                      {"Select business type", ""},
                      {"Fruits", "fruits"},
                      {"Vegetables", "vegetables"},
                      {"Fish", "fish"},
                      {"Meat", "meat"},
                      {"Dairy", "dairy"},
                      {"Bakery", "bakery"},
                      {"Spices", "spices"},
                      {"Other", "other"}
                    ]}
                  />
                </div>

                <div>
                  <.input
                    field={@form[:business_description]}
                    type="textarea"
                    label="Business Description (Optional)"
                    placeholder="Describe your business and the products you sell"
                    rows="3"
                  />
                  <p class="text-xs text-base-content/70 mt-1">
                    Help customers understand what makes your business special
                  </p>
                </div>

                <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                  <div>
                    <.input
                      field={@form[:business_hours]}
                      type="text"
                      label="Business Hours (Optional)"
                      placeholder="e.g., Mon-Fri: 8AM-6PM, Sat: 8AM-2PM"
                    />
                    <p class="text-xs text-base-content/70 mt-1">
                      Let customers know when you're available
                    </p>
                  </div>

                  <div>
                    <.input
                      field={@form[:business_registration_number]}
                      type="text"
                      label="Business Registration Number (Optional)"
                      placeholder="e.g., 202301234567-K (SSM or other registration)"
                    />
                  </div>
                </div>

                <div>
                  <.input
                    field={@form[:website]}
                    type="url"
                    label="Website (Optional)"
                    placeholder="https://your-website.com or social media page"
                  />
                  <p class="text-xs text-base-content/70 mt-1">
                    Your business website or social media page
                  </p>
                </div>

                <h3 class="text-lg font-semibold mb-4 mt-6">Profile Image (Optional)</h3>
                <p class="text-sm text-base-content/70 mb-4">
                  Upload a profile picture or logo to help customers recognize your business.
                </p>

                <div class="form-control">
                  <label class="label">
                    <span class="label-text">Profile Image</span>
                  </label>
                  
    <!-- Current Image Display -->
                  <%= if @user.profile_image do %>
                    <div class="mb-4">
                      <h5 class="font-medium mb-2">Current Image:</h5>
                      <div class="avatar">
                        <div class="w-24 h-24 rounded-lg">
                          <img
                            src={@user.profile_image}
                            alt="Current profile"
                            onerror="this.onerror=null; this.style.display='none'; this.nextElementSibling.style.display='flex';"
                          />
                          <div
                            class="w-24 h-24 bg-neutral text-neutral-content rounded-lg flex items-center justify-center text-lg font-bold"
                            style="display:none;"
                          >
                            {String.first(@user.business_name || @user.name || @user.email)
                            |> String.upcase()}
                          </div>
                        </div>
                      </div>
                    </div>
                  <% end %>
                  
    <!-- File Upload Input -->
                  <div class="form-control">
                    <.live_file_input
                      upload={@uploads.profile_image}
                      class="file-input file-input-bordered w-full"
                    />
                  </div>
                  
    <!-- Drag and Drop Upload Area -->
                  <div
                    class="border-2 border-dashed border-gray-300 rounded-lg p-6 text-center hover:border-primary transition-colors mt-4"
                    phx-drop-target={@uploads.profile_image.ref}
                  >
                    <div class="space-y-2">
                      <.icon name="hero-cloud-arrow-up" class="w-12 h-12 mx-auto text-gray-400" />
                      <div class="text-gray-600">
                        <p class="font-medium">Or drag and drop files here</p>
                        <p class="text-sm">JPG, PNG, WebP up to 5MB</p>
                      </div>
                    </div>
                  </div>
                  
    <!-- Upload Help Text -->
                  <div class="label">
                    <span class="label-text-alt">
                      Max file size: 5MB. Supported formats: JPG, PNG, WebP
                    </span>
                  </div>
                </div>
                
    <!-- Upload Preview -->
                <%= if @uploads.profile_image.entries != [] do %>
                  <div class="mt-4">
                    <h5 class="font-medium mb-2">New Image Preview:</h5>
                    <%= for entry <- @uploads.profile_image.entries do %>
                      <div class="relative inline-block mr-4">
                        <!-- Image Preview -->
                        <.live_img_preview
                          entry={entry}
                          class="w-32 h-32 object-cover rounded-lg border-2 border-gray-200"
                        />
                        
    <!-- Remove Button -->
                        <button
                          type="button"
                          phx-click="cancel-upload"
                          phx-value-ref={entry.ref}
                          class="absolute -top-2 -right-2 btn btn-circle btn-xs btn-error"
                          title="Remove image"
                        >
                          ✕
                        </button>
                        
    <!-- Upload Progress -->
                        <div class="mt-2">
                          <progress
                            class="progress progress-primary w-32"
                            value={entry.progress}
                            max="100"
                          >
                            {entry.progress}%
                          </progress>
                          <div class="text-xs text-center mt-1">
                            {entry.progress}% uploaded
                          </div>
                        </div>
                        
    <!-- File Info -->
                        <div class="text-xs text-gray-500 mt-1 w-32">
                          {entry.client_name}
                          <br />
                          {format_file_size(entry.client_size)}
                        </div>
                      </div>
                    <% end %>
                  </div>
                <% end %>
                
    <!-- Upload Errors -->
                <%= for err <- upload_errors(@uploads.profile_image) do %>
                  <div class="alert alert-error mt-2">
                    <.icon name="hero-exclamation-triangle" class="w-4 h-4" />
                    <span>{error_to_string(err)}</span>
                  </div>
                <% end %>
                
    <!-- Entry Errors -->
                <%= for entry <- @uploads.profile_image.entries do %>
                  <%= for err <- upload_errors(@uploads.profile_image, entry) do %>
                    <div class="alert alert-error mt-2">
                      <.icon name="hero-exclamation-triangle" class="w-4 h-4" />
                      <span>{entry.client_name}: {error_to_string(err)}</span>
                    </div>
                  <% end %>
                <% end %>
                
    <!-- Field Requirements Summary -->
                <div class="card bg-base-200 mt-6 mb-4">
                  <div class="card-body py-4">
                    <h4 class="font-semibold text-sm mb-2">Profile Requirements:</h4>
                    <div class="grid grid-cols-1 md:grid-cols-2 gap-2 text-sm">
                      <div>
                        <p class="font-medium text-primary">Required Fields (*)</p>
                        <ul class="list-disc list-inside ml-2 text-base-content/80">
                          <li>Full Name</li>
                          <li>Phone Number</li>
                          <li>Address</li>
                          <li>Business Name</li>
                        </ul>
                      </div>
                      <div>
                        <p class="font-medium text-base-content/60">Optional Fields</p>
                        <ul class="list-disc list-inside ml-2 text-base-content/60">
                          <li>Business Type</li>
                          <li>Business Description</li>
                          <li>Business Hours</li>
                          <li>Registration Number</li>
                          <li>Website</li>
                          <li>Profile Image</li>
                        </ul>
                      </div>
                    </div>
                    <p class="text-xs text-base-content/70 mt-2">
                      <.icon name="hero-information-circle" class="w-3 h-3 inline" />
                      You must complete all required fields before you can add products.
                    </p>
                  </div>
                </div>

                <div class="form-control mt-6">
                  <.button type="submit" class="btn btn-primary" phx-disable-with="Saving...">
                    <.icon name="hero-check" class="w-4 h-4 mr-2" /> Save Profile
                  </.button>
                </div>
              </.form>
            </div>
          </div>
        </div>
      </div>
      
    <!-- Vendor Statistics -->
      <div class="mt-8">
        <div class="card bg-base-100 shadow-xl">
          <div class="card-body">
            <h3 class="card-title">Your Vendor Statistics</h3>
            <div class="stats stats-vertical lg:stats-horizontal shadow w-full">
              <div class="stat">
                <div class="stat-title">Total Products</div>
                <div class="stat-value text-primary">{@stats.total_products}</div>
                <div class="stat-desc">Listed products</div>
              </div>
              <div class="stat">
                <div class="stat-title">Active Products</div>
                <div class="stat-value text-success">{@stats.active_products}</div>
                <div class="stat-desc">Currently available</div>
              </div>
              <div class="stat">
                <div class="stat-title">Expiring Soon</div>
                <div class="stat-value text-warning">{@stats.expiring_soon}</div>
                <div class="stat-desc">Within 24 hours</div>
              </div>
              <div class="stat">
                <div class="stat-title">Expired Products</div>
                <div class="stat-value text-error">{@stats.expired_products}</div>
                <div class="stat-desc">Need attention</div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    current_scope = socket.assigns.current_scope
    user = current_scope.user

    # Get vendor statistics
    stats = Products.get_vendor_stats(current_scope)

    socket =
      socket
      |> assign(:user, user)
      |> assign(:stats, stats)
      |> assign(:page_title, "Vendor Profile")
      |> assign_form(Accounts.change_user_profile(user))
      |> allow_upload(:profile_image,
        accept: ~w(.jpg .jpeg .png .webp),
        max_entries: 1,
        max_file_size: 5_000_000,
        auto_upload: false
      )

    {:ok, socket}
  end

  @impl true
  def handle_event("validate", %{"user" => user_params}, socket) do
    changeset =
      socket.assigns.user
      |> Accounts.change_user_profile(user_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  @impl true
  def handle_event("save", %{"user" => user_params}, socket) do
    # Consume uploaded files first
    uploaded_files =
      consume_uploaded_entries(socket, :profile_image, fn %{path: path}, entry ->
        upload_dir = "priv/static/uploads"
        File.mkdir_p!(upload_dir)

        ext = Path.extname(entry.client_name) |> String.downcase() |> String.trim_leading(".")
        filename = "#{DateTime.utc_now() |> DateTime.to_unix()}_#{entry.uuid}.#{ext}"
        dest = Path.join(upload_dir, filename)

        File.cp!(path, dest)
        {:ok, "/uploads/#{filename}"}
      end)

    # Add uploaded file URL to user_params if present
    user_params =
      case uploaded_files do
        [url | _] -> Map.put(user_params, "profile_image", url)
        _ -> user_params
      end

    case Accounts.update_user_profile(socket.assigns.user, user_params) do
      {:ok, updated_user} ->
        socket =
          socket
          |> assign(:user, updated_user)
          |> assign_form(Accounts.change_user_profile(updated_user))
          |> put_flash(:info, "Profile updated successfully!")

        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  @impl true
  def handle_event("cancel-upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :profile_image, ref)}
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end

  defp format_file_size(size) when size < 1024, do: "#{size} B"
  defp format_file_size(size) when size < 1024 * 1024, do: "#{Float.round(size / 1024, 1)} KB"
  defp format_file_size(size), do: "#{Float.round(size / (1024 * 1024), 1)} MB"

  defp error_to_string(:too_large), do: "File too large (max 5MB)"
  defp error_to_string(:not_accepted), do: "File type not accepted (only JPG, JPEG, PNG, WebP)"
  defp error_to_string(:too_many_files), do: "Only one file allowed"
  defp error_to_string(:external_client_failure), do: "Upload failed, please try again"
  defp error_to_string(:invalid_file), do: "Invalid file format"
  defp error_to_string(:upload_failed), do: "File upload failed, please try again"
  defp error_to_string(:file_not_found), do: "Uploaded file not found"
  defp error_to_string(err), do: "Upload error: #{inspect(err)}"
end

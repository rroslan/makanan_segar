defmodule MakananSegarWeb.Vendor.DashboardLive do
  use MakananSegarWeb, :live_view
  on_mount {MakananSegarWeb.UserAuthHooks, :require_vendor_user}

  alias MakananSegar.Products
  alias MakananSegar.Products.Product

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        Vendor Dashboard
        <:subtitle>Welcome back, {@user.name || @user.email}!</:subtitle>
        <:actions>
          <.button navigate={~p"/vendor/profile"} class="btn btn-secondary">
            <.icon name="hero-user" class="w-4 h-4 mr-2" /> My Profile
          </.button>
          <%= if @profile_complete do %>
            <.button navigate={~p"/vendor/products/new"} class="btn btn-primary">
              <.icon name="hero-plus" class="w-4 h-4 mr-2" /> Add New Product
            </.button>
          <% else %>
            <button class="btn btn-primary btn-disabled" disabled title="Complete your profile first">
              <.icon name="hero-plus" class="w-4 h-4 mr-2" /> Add New Product
            </button>
          <% end %>
        </:actions>
      </.header>

    <!-- Profile Completion Alert -->
      <%= unless @profile_complete do %>
        <div class="alert alert-warning shadow-lg mb-6">
          <.icon name="hero-exclamation-triangle" class="w-6 h-6" />
          <div>
            <h3 class="font-bold">Complete Your Profile</h3>
            <div class="text-xs">Add your business details to start selling on MakananSegar</div>
          </div>
          <.link navigate={~p"/vendor/profile"} class="btn btn-sm">
            Complete Profile
          </.link>
        </div>
      <% end %>

    <!-- Quick Stats -->
      <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
        <!-- Profile Card -->
        <div
          class="stat bg-gradient-to-br from-primary to-secondary text-primary-content rounded-box shadow cursor-pointer hover:shadow-lg transition-shadow"
          onclick="window.location.href='/vendor/profile'"
        >
          <div class="stat-figure">
            <.icon name="hero-user-circle" class="w-8 h-8" />
          </div>
          <div class="stat-title text-primary-content/90">Your Profile</div>
          <div class="stat-value text-2xl">{@user.business_name || @user.name || "Set Name"}</div>
          <div class="stat-desc text-primary-content/70">
            <%= if @profile_complete do %>
              Click to view profile →
            <% else %>
              <span class="text-warning">⚠️ Incomplete</span>
            <% end %>
          </div>
        </div>

        <div class="stat bg-base-100 rounded-box shadow">
          <div class="stat-figure text-primary">
            <.icon name="hero-cube" class="w-8 h-8" />
          </div>
          <div class="stat-title">Total Products</div>
          <div class="stat-value text-primary">{@stats.total_products}</div>
          <div class="stat-desc">All listed products</div>
        </div>

        <div class="stat bg-base-100 rounded-box shadow">
          <div class="stat-figure text-success">
            <.icon name="hero-check-circle" class="w-8 h-8" />
          </div>
          <div class="stat-title">Active Products</div>
          <div class="stat-value text-success">{@stats.active_products}</div>
          <div class="stat-desc">Currently available</div>
        </div>

        <div class="stat bg-base-100 rounded-box shadow">
          <div class="stat-figure text-warning">
            <.icon name="hero-clock" class="w-8 h-8" />
          </div>
          <div class="stat-title">Expiring Soon</div>
          <div class="stat-value text-warning">{@stats.expiring_soon}</div>
          <div class="stat-desc">Next 24 hours</div>
        </div>

        <div class="stat bg-base-100 rounded-box shadow">
          <div class="stat-figure text-error">
            <.icon name="hero-x-circle" class="w-8 h-8" />
          </div>
          <div class="stat-title">Expired</div>
          <div class="stat-value text-error">{@stats.expired_products}</div>
          <div class="stat-desc">Need attention</div>
        </div>
      </div>

      <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <!-- Recent Products -->
        <div class="card bg-base-100 shadow-xl">
          <div class="card-body">
            <div class="card-title flex justify-between items-center">
              <span>Recent Products</span>
              <.link navigate={~p"/vendor/products"} class="btn btn-sm btn-ghost">
                View All <.icon name="hero-arrow-right" class="w-4 h-4 ml-1" />
              </.link>
            </div>

            <%= if @recent_products == [] do %>
              <div class="text-center py-8">
                <.icon name="hero-cube" class="w-12 h-12 mx-auto text-base-300 mb-4" />
                <p class="text-base-content/70">No products yet</p>
                <%= if @profile_complete do %>
                  <.link navigate={~p"/vendor/products/new"} class="btn btn-primary btn-sm mt-4">
                    Add Your First Product
                  </.link>
                <% else %>
                  <.link navigate={~p"/vendor/profile"} class="btn btn-warning btn-sm mt-4">
                    Complete Profile First
                  </.link>
                <% end %>
              </div>
            <% else %>
              <.render_recent_products_list products={@recent_products} />
            <% end %>
          </div>
        </div>

    <!-- Expiring Products Alert -->
        <div class="card bg-base-100 shadow-xl">
          <div class="card-body">
            <div class="card-title text-warning">
              <.icon name="hero-exclamation-triangle" class="w-5 h-5" /> Products Expiring Soon
            </div>

            <%= if @expiring_products == [] do %>
              <div class="text-center py-8">
                <.icon name="hero-check-circle" class="w-12 h-12 mx-auto text-success mb-4" />
                <p class="text-base-content/70">All products are fresh!</p>
                <p class="text-sm text-base-content/50">No products expiring in the next 24 hours</p>
              </div>
            <% else %>
              <.render_expiring_products_list products={@expiring_products} />
            <% end %>
          </div>
        </div>
      </div>

    <!-- Quick Actions -->
      <div class="mt-8">
        <div class="card bg-base-100 shadow-xl">
          <div class="card-body">
            <h3 class="card-title">Quick Actions</h3>
            <div class="grid grid-cols-2 md:grid-cols-4 gap-4 mt-4">
              <%= if @profile_complete do %>
                <.link navigate={~p"/vendor/products/new"} class="btn btn-outline btn-primary">
                  <.icon name="hero-plus" class="w-4 h-4 mr-2" /> Add Product
                </.link>
              <% else %>
                <button
                  class="btn btn-outline btn-primary btn-disabled"
                  disabled
                  title="Complete your profile first"
                >
                  <.icon name="hero-plus" class="w-4 h-4 mr-2" /> Add Product
                </button>
              <% end %>

              <.link navigate={~p"/vendor/profile"} class="btn btn-outline btn-secondary">
                <.icon name="hero-user" class="w-4 h-4 mr-2" /> Complete Profile
              </.link>

              <.link navigate={~p"/vendor/products"} class="btn btn-outline btn-accent">
                <.icon name="hero-cube" class="w-4 h-4 mr-2" /> Manage Products
              </.link>

              <button class="btn btn-outline btn-info" phx-click="refresh_stats">
                <.icon name="hero-arrow-path" class="w-4 h-4 mr-2" /> Refresh Stats
              </button>
            </div>
          </div>
        </div>
      </div>

    <!-- Malaysia Time -->
      <div class="mt-4 text-center text-sm text-base-content/50">
        Current time (Malaysia): {format_malaysia_time(@current_time)}
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    current_scope = socket.assigns.current_scope
    user = current_scope.user

    # Check if profile is complete (website is optional)
    profile_complete = user.business_name && user.phone && user.address

    # Get current Malaysia time
    current_time = DateTime.now!("Asia/Kuala_Lumpur")

    # Calculate stats using Products context
    stats = Products.get_vendor_stats(current_scope)

    # Get recent products
    recent_products =
      Products.list_products(current_scope)
      |> Enum.sort_by(& &1.inserted_at, {:desc, DateTime})
      |> Enum.take(5)

    # Get expiring products
    expiring_products = Products.list_expiring_soon_products(current_scope)

    socket =
      socket
      |> assign(:user, user)
      |> assign(:stats, stats)
      |> assign(:recent_products, recent_products)
      |> assign(:expiring_products, expiring_products)
      |> assign(:current_time, current_time)
      |> assign(:page_title, "Vendor Dashboard")
      |> assign(:profile_complete, profile_complete)

    # Schedule periodic updates
    if connected?(socket) do
      # Update every minute
      Process.send_after(self(), :update_time, 60_000)
    end

    {:ok, socket}
  end

  @impl true
  def handle_event("refresh_stats", _params, socket) do
    current_scope = socket.assigns.current_scope
    stats = Products.get_vendor_stats(current_scope)

    recent_products =
      Products.list_products(current_scope)
      |> Enum.sort_by(& &1.inserted_at, {:desc, DateTime})
      |> Enum.take(5)

    expiring_products = Products.list_expiring_soon_products(current_scope)

    socket =
      socket
      |> assign(:stats, stats)
      |> assign(:recent_products, recent_products)
      |> assign(:expiring_products, expiring_products)
      |> put_flash(:info, "Stats refreshed!")

    {:noreply, socket}
  end

  @impl true
  def handle_info(:update_time, socket) do
    current_time = DateTime.now!("Asia/Kuala_Lumpur")

    # Schedule next update
    Process.send_after(self(), :update_time, 60_000)

    {:noreply, assign(socket, :current_time, current_time)}
  end

  defp format_time_until_expiry(expires_at) do
    now = DateTime.utc_now()
    diff = DateTime.diff(expires_at, now, :second)

    cond do
      diff <= 0 -> "Expired"
      diff < 3600 -> "#{div(diff, 60)} min left"
      diff < 86400 -> "#{div(diff, 3600)} hr left"
      true -> "#{div(diff, 86400)} days left"
    end
  end

  defp format_malaysia_time(datetime) do
    Calendar.strftime(datetime, "%B %d, %Y at %I:%M %p %Z")
  end

  defp render_recent_products_list(assigns) do
    ~H"""
    <div class="space-y-3">
      <%= for recent_item <- @products do %>
        <%= Phoenix.Component.with_assigns %{recent_item: recent_item} do %>
          <.link
            navigate={~p"/vendor/products/#{@recent_item.id}"}
            class="flex items-center gap-3 p-3 border border-base-300 rounded-lg hover:bg-base-50 hover:shadow-md transition-all cursor-pointer group"
          >
            <div class="avatar">
              <div class="w-12 h-12 rounded">
                <%= if @recent_item.image do %>
                  <img src={@recent_item.image} alt={@recent_item.name} />
                <% else %>
                  <div class="bg-primary text-primary-content w-12 h-12 flex items-center justify-center">
                    {String.first(@recent_item.name) |> String.upcase()}
                  </div>
                <% end %>
              </div>
            </div>
            <div class="flex-1">
              <h4 class="font-semibold text-sm group-hover:text-primary">
                {@recent_item.name}
              </h4>
              <p class="text-xs text-base-content/70">{@recent_item.category}</p>
              <p class="text-xs font-medium">RM {@recent_item.price}</p>
            </div>
            <div class="flex items-center gap-2">
              <div class="flex flex-col items-end gap-1">
                <div class={"badge badge-sm #{if @recent_item.is_active, do: "badge-success", else: "badge-error"}"}>
                  {if @recent_item.is_active, do: "Active", else: "Inactive"}
                </div>
                <span class="text-xs text-base-content/50">
                  {if Product.expired?(@recent_item),
                    do: "Expired",
                    else: format_time_until_expiry(@recent_item.expires_at)}
                </span>
              </div>
            </div>
          </.link>
        <% end %>
      <% end %>
    </div>
    """
  end

  defp render_expiring_products_list(assigns) do
    ~H"""
    <div class="space-y-3">
      <%= for expiring_item <- @products do %>
        <div class="alert alert-warning">
          <.icon name="hero-clock" class="w-4 h-4" />
          <div class="flex-1">
            <p class="font-semibold text-sm">{expiring_item.name}</p>
            <p class="text-xs">
              Expires {format_time_until_expiry(expiring_item.expires_at)}
            </p>
          </div>
          <div class="flex gap-2">
            <.link navigate={~p"/vendor/products/#{expiring_item.id}"} class="btn btn-xs btn-ghost">
              View
            </.link>
            <.link
              navigate={~p"/vendor/products/#{expiring_item.id}/edit"}
              class="btn btn-xs btn-outline"
            >
              Edit
            </.link>
          </div>
        </div>
      <% end %>
    </div>
    """
  end
end

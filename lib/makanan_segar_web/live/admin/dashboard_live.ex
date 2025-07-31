defmodule MakananSegarWeb.Admin.DashboardLive do
  use MakananSegarWeb, :live_view
  on_mount {MakananSegarWeb.UserAuthHooks, :require_admin_user}

  alias MakananSegar.Accounts

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        Admin Dashboard
        <:subtitle>System Overview and User Management</:subtitle>
        <:actions>
          <.button navigate={~p"/admin/users"} class="btn btn-primary">
            <.icon name="hero-users" class="w-4 h-4 mr-2" /> Manage Users
          </.button>
        </:actions>
      </.header>

    <!-- Quick Stats -->
      <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
        <div class="stat bg-base-100 rounded-box shadow">
          <div class="stat-figure text-primary">
            <.icon name="hero-users" class="w-8 h-8" />
          </div>
          <div class="stat-title">Total Users</div>
          <div class="stat-value text-primary">{@stats.total_users}</div>
          <div class="stat-desc">All registered users</div>
        </div>

        <div class="stat bg-base-100 rounded-box shadow">
          <div class="stat-figure text-success">
            <.icon name="hero-building-storefront" class="w-8 h-8" />
          </div>
          <div class="stat-title">Active Vendors</div>
          <div class="stat-value text-success">{@stats.total_vendors}</div>
          <div class="stat-desc">Verified vendors</div>
        </div>

        <div class="stat bg-base-100 rounded-box shadow">
          <div class="stat-figure text-info">
            <.icon name="hero-shield-check" class="w-8 h-8" />
          </div>
          <div class="stat-title">Admins</div>
          <div class="stat-value text-info">{@stats.total_admins}</div>
          <div class="stat-desc">System administrators</div>
        </div>

        <div class="stat bg-base-100 rounded-box shadow">
          <div class="stat-figure text-warning">
            <.icon name="hero-user" class="w-8 h-8" />
          </div>
          <div class="stat-title">Regular Users</div>
          <div class="stat-value text-warning">{@stats.regular_users}</div>
          <div class="stat-desc">Potential vendors</div>
        </div>
      </div>

      <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <!-- Recent Users -->
        <div class="card bg-base-100 shadow-xl">
          <div class="card-body">
            <div class="card-title flex justify-between items-center">
              <span>Recent Users</span>
              <.link navigate={~p"/admin/users"} class="btn btn-sm btn-ghost">
                View All <.icon name="hero-arrow-right" class="w-4 h-4 ml-1" />
              </.link>
            </div>

            <%= if @recent_users == [] do %>
              <div class="text-center py-8">
                <.icon name="hero-users" class="w-12 h-12 mx-auto text-base-300 mb-4" />
                <p class="text-base-content/70">No users yet</p>
              </div>
            <% else %>
              <div class="space-y-3">
                <%= for user <- @recent_users do %>
                  <div class="flex items-center gap-3 p-3 border border-base-300 rounded-lg hover:bg-base-50">
                    <div class="avatar">
                      <div class="w-10 h-10 rounded-full">
                        <%= if user.profile_image do %>
                          <img src={user.profile_image} alt={user.name} />
                        <% else %>
                          <div class="bg-primary text-primary-content w-10 h-10 flex items-center justify-center">
                            {String.first(user.name || user.email) |> String.upcase()}
                          </div>
                        <% end %>
                      </div>
                    </div>
                    <div class="flex-1">
                      <h4 class="font-semibold text-sm">{user.name || "Unnamed"}</h4>
                      <p class="text-xs text-base-content/70">{user.email}</p>
                    </div>
                    <div class="flex flex-col items-end gap-1">
                      <div class="flex gap-1">
                        <%= if user.is_admin do %>
                          <div class="badge badge-info badge-sm">Admin</div>
                        <% end %>
                        <%= if user.is_vendor do %>
                          <div class="badge badge-success badge-sm">Vendor</div>
                        <% end %>
                        <%= if !user.is_admin && !user.is_vendor do %>
                          <div class="badge badge-ghost badge-sm">User</div>
                        <% end %>
                      </div>
                      <span class="text-xs text-base-content/50">
                        {format_time_ago(user.inserted_at)}
                      </span>
                    </div>
                  </div>
                <% end %>
              </div>
            <% end %>
          </div>
        </div>

    <!-- Pending Vendor Requests -->
        <div class="card bg-base-100 shadow-xl">
          <div class="card-body">
            <div class="card-title text-warning">
              <.icon name="hero-clock" class="w-5 h-5" /> Pending Vendor Requests
            </div>

            <%= if @pending_requests == [] do %>
              <div class="text-center py-8">
                <.icon name="hero-check-circle" class="w-12 h-12 mx-auto text-success mb-4" />
                <p class="text-base-content/70">No pending requests</p>
                <p class="text-sm text-base-content/50">All vendor requests have been processed</p>
              </div>
            <% else %>
              <div class="space-y-3">
                <%= for user <- @pending_requests do %>
                  <div class="alert">
                    <.icon name="hero-user-plus" class="w-4 h-4" />
                    <div class="flex-1">
                      <h4 class="font-semibold">{user.name || "Unnamed User"}</h4>
                      <p class="text-sm">{user.email}</p>
                      <p class="text-xs text-base-content/70">
                        Registered: {format_time_ago(user.inserted_at)}
                      </p>
                    </div>
                    <div class="flex gap-2">
                      <button
                        phx-click="promote_to_vendor"
                        phx-value-user-id={user.id}
                        class="btn btn-xs btn-success"
                        data-confirm="Promote #{user.name || user.email} to vendor?"
                      >
                        Make Vendor
                      </button>
                      <.link navigate={~p"/admin/users/#{user.id}"} class="btn btn-xs btn-outline">
                        View
                      </.link>
                    </div>
                  </div>
                <% end %>
              </div>
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
              <.link navigate={~p"/admin/users"} class="btn btn-outline btn-primary">
                <.icon name="hero-users" class="w-4 h-4 mr-2" /> Manage Users
              </.link>

              <button class="btn btn-outline btn-secondary" phx-click="refresh_stats">
                <.icon name="hero-arrow-path" class="w-4 h-4 mr-2" /> Refresh Stats
              </button>

              <.link navigate={~p"/users/settings"} class="btn btn-outline btn-accent">
                <.icon name="hero-cog-6-tooth" class="w-4 h-4 mr-2" /> Settings
              </.link>

              <.link navigate={~p"/"} class="btn btn-outline btn-info">
                <.icon name="hero-cube" class="w-4 h-4 mr-2" /> View Products
              </.link>
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
    # Get current Malaysia time
    current_time = DateTime.now!("Asia/Kuala_Lumpur")

    # Calculate stats
    stats = calculate_admin_stats()

    # Get recent users (last 10)
    recent_users =
      Accounts.list_users()
      |> Enum.sort_by(& &1.inserted_at, {:desc, DateTime})
      |> Enum.take(10)

    # Get pending vendor requests (users who are not vendors or admins yet)
    pending_requests =
      Accounts.list_users()
      |> Enum.filter(&(!&1.is_vendor && !&1.is_admin))
      |> Enum.sort_by(& &1.inserted_at, {:desc, DateTime})
      |> Enum.take(10)

    socket =
      socket
      |> assign(:stats, stats)
      |> assign(:recent_users, recent_users)
      |> assign(:pending_requests, pending_requests)
      |> assign(:current_time, current_time)
      |> assign(:page_title, "Admin Dashboard")

    # Schedule periodic updates
    if connected?(socket) do
      # Update every minute
      Process.send_after(self(), :update_time, 60_000)
    end

    {:ok, socket}
  end

  @impl true
  def handle_event("refresh_stats", _params, socket) do
    stats = calculate_admin_stats()

    recent_users =
      Accounts.list_users()
      |> Enum.sort_by(& &1.inserted_at, {:desc, DateTime})
      |> Enum.take(10)

    pending_requests =
      Accounts.list_users()
      |> Enum.filter(&(!&1.is_vendor && !&1.is_admin))
      |> Enum.sort_by(& &1.inserted_at, {:desc, DateTime})
      |> Enum.take(10)

    socket =
      socket
      |> assign(:stats, stats)
      |> assign(:recent_users, recent_users)
      |> assign(:pending_requests, pending_requests)
      |> put_flash(:info, "Dashboard refreshed!")

    {:noreply, socket}
  end

  @impl true
  def handle_event("promote_to_vendor", %{"user-id" => user_id}, socket) do
    user = Accounts.get_user!(user_id)

    case Accounts.update_user_roles(user, %{"is_vendor" => true}) do
      {:ok, updated_user} ->
        # Refresh pending requests
        pending_requests =
          Accounts.list_users()
          |> Enum.filter(&(!&1.is_vendor && !&1.is_admin))
          |> Enum.sort_by(& &1.inserted_at, {:desc, DateTime})
          |> Enum.take(10)

        # Refresh stats
        stats = calculate_admin_stats()

        socket =
          socket
          |> assign(:pending_requests, pending_requests)
          |> assign(:stats, stats)
          |> put_flash(
            :info,
            "#{updated_user.name || updated_user.email} has been promoted to vendor!"
          )

        {:noreply, socket}

      {:error, _changeset} ->
        socket =
          socket
          |> put_flash(:error, "Failed to promote user to vendor.")

        {:noreply, socket}
    end
  end

  @impl true
  def handle_info(:update_time, socket) do
    current_time = DateTime.now!("Asia/Kuala_Lumpur")

    # Schedule next update
    Process.send_after(self(), :update_time, 60_000)

    {:noreply, assign(socket, :current_time, current_time)}
  end

  defp calculate_admin_stats do
    all_users = Accounts.list_users()
    total_users = length(all_users)
    total_vendors = length(Accounts.list_vendors())
    total_admins = length(Accounts.list_admins())
    regular_users = total_users - total_vendors - total_admins

    %{
      total_users: total_users,
      total_vendors: total_vendors,
      total_admins: total_admins,
      regular_users: regular_users
    }
  end

  defp format_time_ago(datetime) do
    now = DateTime.utc_now()
    diff = DateTime.diff(now, datetime, :second)

    cond do
      diff < 60 -> "Just now"
      diff < 3600 -> "#{div(diff, 60)} min ago"
      diff < 86400 -> "#{div(diff, 3600)} hr ago"
      true -> "#{div(diff, 86400)} days ago"
    end
  end

  defp format_malaysia_time(datetime) do
    Calendar.strftime(datetime, "%B %d, %Y at %I:%M %p MYT")
  end
end

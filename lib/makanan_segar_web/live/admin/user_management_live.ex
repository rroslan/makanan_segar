defmodule MakananSegarWeb.Admin.UserManagementLive do
  use MakananSegarWeb, :live_view
  on_mount {MakananSegarWeb.UserAuthHooks, :require_admin_user}

  alias MakananSegar.Accounts
  alias MakananSegar.Accounts.User

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        User Management
        <:subtitle>Manage all users, vendors, and admins</:subtitle>
        <:actions>
          <button phx-click="refresh_users" class="btn btn-outline">
            <.icon name="hero-arrow-path" class="w-4 h-4 mr-2" /> Refresh
          </button>
        </:actions>
      </.header>

      <div class="space-y-6">
        <!-- Filter and Search -->
        <div class="card bg-base-100 shadow">
          <div class="card-body">
            <div class="flex flex-col lg:flex-row gap-4">
              <!-- Role Filter -->
              <div class="flex-1">
                <label class="label">
                  <span class="label-text">Filter by Role</span>
                </label>
                <div class="join">
                  <button
                    phx-click="filter_role"
                    phx-value-role=""
                    class={"btn join-item #{if @filter_role == "", do: "btn-active", else: "btn-outline"}"}
                  >
                    All Users ({@total_count})
                  </button>
                  <button
                    phx-click="filter_role"
                    phx-value-role="admin"
                    class={"btn join-item #{if @filter_role == "admin", do: "btn-active", else: "btn-outline"}"}
                  >
                    Admins ({@admin_count})
                  </button>
                  <button
                    phx-click="filter_role"
                    phx-value-role="vendor"
                    class={"btn join-item #{if @filter_role == "vendor", do: "btn-active", else: "btn-outline"}"}
                  >
                    Vendors ({@vendor_count})
                  </button>
                  <button
                    phx-click="filter_role"
                    phx-value-role="regular"
                    class={"btn join-item #{if @filter_role == "regular", do: "btn-active", else: "btn-outline"}"}
                  >
                    Regular ({@regular_count})
                  </button>
                </div>
              </div>
              
    <!-- Search -->
              <div class="flex-1">
                <label class="label">
                  <span class="label-text">Search Users</span>
                </label>
                <div class="join w-full">
                  <input
                    type="text"
                    placeholder="Search by name or email..."
                    class="input input-bordered join-item flex-1"
                    phx-keyup="search"
                    phx-debounce="300"
                    value={@search_term}
                  />
                  <button class="btn btn-primary join-item">
                    <.icon name="hero-magnifying-glass" class="w-4 h-4" />
                  </button>
                </div>
              </div>
            </div>
          </div>
        </div>
        
    <!-- Users Table -->
        <div class="card bg-base-100 shadow">
          <div class="card-body">
            <%= if @loading do %>
              <div class="text-center py-12">
                <span class="loading loading-spinner loading-lg"></span>
                <p class="mt-4">Loading users...</p>
              </div>
            <% else %>
              <%= if @filtered_users == [] do %>
                <div class="text-center py-12">
                  <div class="text-6xl mb-8">👥</div>
                  <h3 class="text-2xl font-bold mb-4">No users found</h3>
                  <p class="text-base-content/70">
                    <%= if @search_term != "" do %>
                      No users match your search "{@search_term}"
                    <% else %>
                      No users match the selected filter
                    <% end %>
                  </p>
                </div>
              <% else %>
                <div class="overflow-x-auto">
                  <table class="table table-zebra">
                    <thead>
                      <tr>
                        <th>User</th>
                        <th>Email</th>
                        <th>Roles</th>
                        <th>Status</th>
                        <th>Joined</th>
                        <th>Actions</th>
                      </tr>
                    </thead>
                    <tbody>
                      <%= for user <- @filtered_users do %>
                        <tr>
                          <td>
                            <div class="flex items-center gap-3">
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
                              <div>
                                <div class="font-bold">{user.name || "Unnamed"}</div>
                                <div class="text-sm opacity-50">
                                  ID: {user.id}
                                </div>
                              </div>
                            </div>
                          </td>
                          <td>
                            <span class="text-sm">{user.email}</span>
                          </td>
                          <td>
                            <div class="flex flex-wrap gap-1">
                              <%= if user.is_admin do %>
                                <div class="badge badge-error badge-sm">Admin</div>
                              <% end %>
                              <%= if user.is_vendor do %>
                                <div class="badge badge-success badge-sm">Vendor</div>
                              <% end %>
                              <%= if !user.is_admin && !user.is_vendor do %>
                                <div class="badge badge-ghost badge-sm">Regular</div>
                              <% end %>
                            </div>
                          </td>
                          <td>
                            <div class={"badge badge-sm #{if User.confirmed?(user), do: "badge-success", else: "badge-warning"}"}>
                              {if User.confirmed?(user), do: "Confirmed", else: "Pending"}
                            </div>
                          </td>
                          <td class="text-sm">
                            {format_date(user.inserted_at)}
                          </td>
                          <td>
                            <div class="dropdown dropdown-left">
                              <div tabindex="0" role="button" class="btn btn-xs btn-outline">
                                Actions <.icon name="hero-chevron-down" class="w-3 h-3" />
                              </div>
                              <ul
                                tabindex="0"
                                class="dropdown-content z-[1] menu p-2 shadow bg-base-100 rounded-box w-52"
                              >
                                <li>
                                  <.link navigate={~p"/admin/users/#{user.id}"}>
                                    <.icon name="hero-eye" class="w-4 h-4" /> View Details
                                  </.link>
                                </li>

                                <%= if !user.is_vendor do %>
                                  <li>
                                    <button
                                      phx-click="promote_to_vendor"
                                      phx-value-user-id={user.id}
                                      data-confirm="Promote #{user.name || user.email} to vendor?"
                                    >
                                      <.icon name="hero-building-storefront" class="w-4 h-4" />
                                      Make Vendor
                                    </button>
                                  </li>
                                <% else %>
                                  <li>
                                    <button
                                      phx-click="revoke_vendor"
                                      phx-value-user-id={user.id}
                                      data-confirm="Revoke vendor status from #{user.name || user.email}?"
                                    >
                                      <.icon name="hero-x-mark" class="w-4 h-4" /> Revoke Vendor
                                    </button>
                                  </li>
                                <% end %>

                                <%= if !user.is_admin && user.id != @current_scope.user.id do %>
                                  <li>
                                    <button
                                      phx-click="promote_to_admin"
                                      phx-value-user-id={user.id}
                                      data-confirm="Promote #{user.name || user.email} to admin? This is a powerful role."
                                    >
                                      <.icon name="hero-shield-check" class="w-4 h-4" /> Make Admin
                                    </button>
                                  </li>
                                <% end %>

                                <%= if user.is_admin && user.id != @current_scope.user.id do %>
                                  <li>
                                    <button
                                      phx-click="revoke_admin"
                                      phx-value-user-id={user.id}
                                      data-confirm="Revoke admin status from #{user.name || user.email}?"
                                    >
                                      <.icon name="hero-x-mark" class="w-4 h-4" /> Revoke Admin
                                    </button>
                                  </li>
                                <% end %>

                                <%= if user.id != @current_scope.user.id do %>
                                  <li class="border-t border-base-300 mt-2">
                                    <button
                                      phx-click="delete_user"
                                      phx-value-user-id={user.id}
                                      data-confirm="Are you sure you want to delete #{user.name || user.email}? This action cannot be undone."
                                      class="text-error"
                                    >
                                      <.icon name="hero-trash" class="w-4 h-4" /> Delete User
                                    </button>
                                  </li>
                                <% end %>
                              </ul>
                            </div>
                          </td>
                        </tr>
                      <% end %>
                    </tbody>
                  </table>
                </div>
              <% end %>
            <% end %>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:loading, true)
      |> assign(:users, [])
      |> assign(:filtered_users, [])
      |> assign(:filter_role, "")
      |> assign(:search_term, "")
      |> assign(:total_count, 0)
      |> assign(:admin_count, 0)
      |> assign(:vendor_count, 0)
      |> assign(:regular_count, 0)
      |> assign(:page_title, "User Management")

    # Load users asynchronously
    send(self(), :load_users)

    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => user_id}, _uri, socket) do
    # Handle showing individual user
    case Integer.parse(user_id) do
      {id, ""} ->
        try do
          user = Accounts.get_user!(id)
          socket = assign(socket, :selected_user, user)
          {:noreply, socket}
        rescue
          Ecto.NoResultsError ->
            socket =
              socket
              |> put_flash(:error, "User not found")
              |> push_navigate(to: ~p"/admin/users")

            {:noreply, socket}
        end

      _ ->
        socket =
          socket
          |> put_flash(:error, "Invalid user ID")
          |> push_navigate(to: ~p"/admin/users")

        {:noreply, socket}
    end
  end

  @impl true
  def handle_params(_params, _uri, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("filter_role", %{"role" => role}, socket) do
    socket =
      socket
      |> assign(:filter_role, role)
      |> assign(:loading, true)

    send(self(), :filter_users)

    {:noreply, socket}
  end

  @impl true
  def handle_event("search", %{"value" => search_term}, socket) do
    socket =
      socket
      |> assign(:search_term, search_term)
      |> assign(:loading, true)

    send(self(), :filter_users)

    {:noreply, socket}
  end

  @impl true
  def handle_event("refresh_users", _params, socket) do
    socket = assign(socket, :loading, true)
    send(self(), :load_users)

    socket =
      socket
      |> put_flash(:info, "Users refreshed!")

    {:noreply, socket}
  end

  @impl true
  def handle_event("promote_to_vendor", %{"user-id" => user_id}, socket) do
    user = Accounts.get_user!(user_id)

    case Accounts.update_user_roles(user, %{"is_vendor" => true}) do
      {:ok, _updated_user} ->
        send(self(), :load_users)

        socket =
          socket
          |> put_flash(:info, "#{user.name || user.email} has been promoted to vendor!")

        {:noreply, socket}

      {:error, _changeset} ->
        socket =
          socket
          |> put_flash(:error, "Failed to promote user to vendor.")

        {:noreply, socket}
    end
  end

  @impl true
  def handle_event("revoke_vendor", %{"user-id" => user_id}, socket) do
    user = Accounts.get_user!(user_id)

    case Accounts.update_user_roles(user, %{"is_vendor" => false}) do
      {:ok, _updated_user} ->
        send(self(), :load_users)

        socket =
          socket
          |> put_flash(:info, "Vendor status revoked from #{user.name || user.email}")

        {:noreply, socket}

      {:error, _changeset} ->
        socket =
          socket
          |> put_flash(:error, "Failed to revoke vendor status.")

        {:noreply, socket}
    end
  end

  @impl true
  def handle_event("promote_to_admin", %{"user-id" => user_id}, socket) do
    user = Accounts.get_user!(user_id)

    case Accounts.update_user_roles(user, %{"is_admin" => true}) do
      {:ok, _updated_user} ->
        send(self(), :load_users)

        socket =
          socket
          |> put_flash(:info, "#{user.name || user.email} has been promoted to admin!")

        {:noreply, socket}

      {:error, _changeset} ->
        socket =
          socket
          |> put_flash(:error, "Failed to promote user to admin.")

        {:noreply, socket}
    end
  end

  @impl true
  def handle_event("revoke_admin", %{"user-id" => user_id}, socket) do
    user = Accounts.get_user!(user_id)

    case Accounts.update_user_roles(user, %{"is_admin" => false}) do
      {:ok, _updated_user} ->
        send(self(), :load_users)

        socket =
          socket
          |> put_flash(:info, "Admin status revoked from #{user.name || user.email}")

        {:noreply, socket}

      {:error, _changeset} ->
        socket =
          socket
          |> put_flash(:error, "Failed to revoke admin status.")

        {:noreply, socket}
    end
  end

  @impl true
  def handle_event("delete_user", %{"user-id" => user_id}, socket) do
    user = Accounts.get_user!(user_id)

    case Accounts.delete_user(user) do
      {:ok, _deleted_user} ->
        send(self(), :load_users)

        socket =
          socket
          |> put_flash(:info, "User #{user.name || user.email} has been deleted")

        {:noreply, socket}

      {:error, _changeset} ->
        socket =
          socket
          |> put_flash(:error, "Failed to delete user.")

        {:noreply, socket}
    end
  end

  @impl true
  def handle_info(:load_users, socket) do
    users = Accounts.list_users()

    # Calculate counts
    total_count = length(users)
    admin_count = Enum.count(users, & &1.is_admin)
    vendor_count = Enum.count(users, & &1.is_vendor)
    regular_count = total_count - admin_count - vendor_count

    socket =
      socket
      |> assign(:users, users)
      |> assign(:total_count, total_count)
      |> assign(:admin_count, admin_count)
      |> assign(:vendor_count, vendor_count)
      |> assign(:regular_count, regular_count)
      |> assign(:loading, false)

    send(self(), :filter_users)

    {:noreply, socket}
  end

  @impl true
  def handle_info(:filter_users, socket) do
    filtered_users = filter_users(socket.assigns.users, socket.assigns)

    socket =
      socket
      |> assign(:filtered_users, filtered_users)
      |> assign(:loading, false)

    {:noreply, socket}
  end

  defp filter_users(users, assigns) do
    users
    |> filter_by_role(assigns.filter_role)
    |> filter_by_search(assigns.search_term)
    |> Enum.sort_by(& &1.inserted_at, {:desc, DateTime})
  end

  defp filter_by_role(users, ""), do: users

  defp filter_by_role(users, "admin") do
    Enum.filter(users, & &1.is_admin)
  end

  defp filter_by_role(users, "vendor") do
    Enum.filter(users, & &1.is_vendor)
  end

  defp filter_by_role(users, "regular") do
    Enum.filter(users, &(!&1.is_admin && !&1.is_vendor))
  end

  defp filter_by_search(users, ""), do: users

  defp filter_by_search(users, search_term) do
    search_term = String.downcase(search_term)

    Enum.filter(users, fn user ->
      String.contains?(String.downcase(user.name || ""), search_term) ||
        String.contains?(String.downcase(user.email), search_term)
    end)
  end

  defp format_date(datetime) do
    datetime
    |> DateTime.shift_zone!("Asia/Kuala_Lumpur")
    |> Calendar.strftime("%b %d, %Y")
  end
end

defmodule MakananSegarWeb.PublicLive.HomeLive do
  use MakananSegarWeb, :live_view

  alias MakananSegar.Products
  alias MakananSegar.Products.Product

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-base-100">
      <!-- Navigation Bar -->
      <div class="navbar bg-base-100 shadow-md sticky top-0 z-50">
        <div class="navbar-start">
          <.link navigate={~p"/"} class="btn btn-ghost text-xl">
            <span class="text-2xl mr-2">🥬</span>
            <span class="hidden sm:inline">MakananSegar</span>
          </.link>
        </div>

        <div class="navbar-center hidden lg:flex">
          <!-- Navigation links removed - home page shows all products -->
        </div>

        <div class="navbar-end">
          <%= if assigns[:current_user] do %>
            <div class="flex items-center gap-2">
              <%= if @current_user.is_admin do %>
                <.link navigate={~p"/admin"} class="btn btn-primary btn-sm">
                  Admin Dashboard
                </.link>
              <% end %>
              <%= if @current_user.is_vendor do %>
                <.link navigate={~p"/vendor"} class="btn btn-success btn-sm">
                  Vendor Dashboard
                </.link>
              <% end %>
              
    <!-- User dropdown -->
              <div class="dropdown dropdown-end">
                <div tabindex="0" role="button" class="btn btn-ghost btn-circle avatar">
                  <div class="w-10 rounded-full">
                    <%= if @current_user.profile_image do %>
                      <img src={@current_user.profile_image} alt={@current_user.name || "User"} />
                    <% else %>
                      <div class="w-10 h-10 rounded-full bg-primary text-primary-content flex items-center justify-center">
                        <svg
                          xmlns="http://www.w3.org/2000/svg"
                          fill="none"
                          viewBox="0 0 24 24"
                          stroke-width="1.5"
                          stroke="currentColor"
                          class="w-6 h-6"
                        >
                          <path
                            stroke-linecap="round"
                            stroke-linejoin="round"
                            d="M15.75 6a3.75 3.75 0 11-7.5 0 3.75 3.75 0 017.5 0zM4.501 20.118a7.5 7.5 0 0114.998 0A17.933 17.933 0 0112 21.75c-2.676 0-5.216-.584-7.499-1.632z"
                          />
                        </svg>
                      </div>
                    <% end %>
                  </div>
                </div>
                <ul
                  tabindex="0"
                  class="menu menu-sm dropdown-content mt-3 z-[1] p-2 shadow bg-base-100 rounded-box w-52"
                >
                  <li class="menu-title">
                    <span>{@current_user.name || @current_user.email}</span>
                  </li>
                  <li><.link navigate={~p"/users/settings"}>Settings</.link></li>
                  <li>
                    <.form for={%{}} action={~p"/users/log-out"} method="delete" class="w-full">
                      <button
                        type="submit"
                        class="w-full text-left px-4 py-2 hover:bg-base-200 rounded-lg transition-colors"
                        onclick="this.disabled=true; this.innerHTML='Logging out...'; this.form.submit();"
                      >
                        Log out
                      </button>
                    </.form>
                  </li>
                </ul>
              </div>
            </div>
          <% else %>
            <!-- User dropdown for non-authenticated users -->
            <div class="dropdown dropdown-end">
              <div tabindex="0" role="button" class="btn btn-ghost btn-circle">
                <svg
                  xmlns="http://www.w3.org/2000/svg"
                  fill="none"
                  viewBox="0 0 24 24"
                  stroke-width="1.5"
                  stroke="currentColor"
                  class="w-6 h-6"
                >
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    d="M15.75 6a3.75 3.75 0 11-7.5 0 3.75 3.75 0 017.5 0zM4.501 20.118a7.5 7.5 0 0114.998 0A17.933 17.933 0 0112 21.75c-2.676 0-5.216-.584-7.499-1.632z"
                  />
                </svg>
              </div>
              <ul
                tabindex="0"
                class="menu menu-sm dropdown-content mt-3 z-[1] p-2 shadow bg-base-100 rounded-box w-52"
              >
                <li><.link navigate={~p"/users/log-in"}>Log in</.link></li>
                <li><.link navigate={~p"/users/register"}>Register</.link></li>
                <li class="menu-title mt-2">
                  <span>For Vendors</span>
                </li>
                <li><.link navigate={~p"/users/register"}>Become a Vendor</.link></li>
              </ul>
            </div>
          <% end %>
        </div>
      </div>
      
    <!-- Products Grid -->
      <div class="container mx-auto px-4 py-8">
        <%= if @products == [] do %>
          <div class="text-center py-16">
            <div class="text-6xl mb-8">🥬</div>
            <h3 class="text-2xl font-bold mb-4">No products available</h3>
            <p class="text-base-content/70">Check back soon for fresh products!</p>
          </div>
        <% else %>
          <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6">
            <%= for product <- @products do %>
              <div
                id={"product-#{product.id}"}
                class="card bg-base-100 shadow-xl hover:shadow-2xl transition-all duration-300 h-full"
              >
                <!-- Product Image -->
                <.link navigate={~p"/products/#{product.id}"} class="group">
                  <figure class="px-4 pt-4">
                    <div class="w-full h-48 rounded-lg overflow-hidden bg-base-200">
                      <%= if product.image do %>
                        <img
                          src={product.image}
                          alt={product.name}
                          class="w-full h-full object-cover group-hover:scale-105 transition-transform duration-300"
                        />
                      <% else %>
                        <div class="w-full h-full flex items-center justify-center text-6xl">
                          <%= case product.category do %>
                            <% "fish" -> %>
                              🐟
                            <% "vegetables" -> %>
                              🥬
                            <% "fruits" -> %>
                              🥭
                            <% _ -> %>
                              📦
                          <% end %>
                        </div>
                      <% end %>
                    </div>
                  </figure>
                </.link>

                <div class="card-body p-4">
                  <!-- Category Badge -->
                  <div class={"badge badge-sm #{category_badge_class(product.category)} mb-2"}>
                    {Product.category_display_name(product.category)}
                  </div>
                  
    <!-- Product Name -->
                  <.link navigate={~p"/products/#{product.id}"} class="hover:text-primary">
                    <h3 class="card-title text-lg line-clamp-1">{product.name}</h3>
                  </.link>
                  
    <!-- Description -->
                  <p class="text-sm text-base-content/70 line-clamp-2 flex-grow">
                    {product.description || "Fresh product from local vendor"}
                  </p>
                  
    <!-- Price -->
                  <div class="text-2xl font-bold text-primary mt-2">
                    RM {product.price}
                  </div>
                  
    <!-- Expiry Info -->
                  <div class="text-xs text-base-content/60 mt-1">
                    <%= if Product.expired?(product) do %>
                      <span class="text-error">Expired</span>
                    <% else %>
                      Expires {format_time_until_expiry(product.expires_at)}
                    <% end %>
                  </div>
                  
    <!-- Vendor Info with Avatar -->
                  <%= if product.user do %>
                    <.link
                      navigate={~p"/vendors/#{product.user.id}"}
                      class="flex items-center gap-2 mt-3 text-xs text-base-content/60 hover:text-primary transition-colors"
                    >
                      <div class="avatar">
                        <div class="w-6 h-6 rounded-full">
                          <%= if product.user.profile_image do %>
                            <img src={product.user.profile_image} alt={product.user.name || "Vendor"} />
                          <% else %>
                            <div class="bg-base-300 text-base-content w-full h-full flex items-center justify-center text-xs">
                              {String.first(product.user.name || product.user.email)
                              |> String.upcase()}
                            </div>
                          <% end %>
                        </div>
                      </div>
                      <div class="flex-1 min-w-0">
                        <p class="text-sm font-medium group-hover:text-primary transition-colors">
                          {product.user.business_name || product.user.name || "Local vendor"}
                        </p>
                      </div>
                      <.icon name="hero-arrow-right" class="w-3 h-3" />
                    </.link>
                  <% end %>
                </div>
              </div>
            <% end %>
          </div>
        <% end %>
      </div>
    </div>
    """
  end

  @impl true
  def mount(_params, session, socket) do
    # Get current user from session
    current_user =
      case session["user_token"] do
        nil ->
          nil

        token ->
          case MakananSegar.Accounts.get_user_by_session_token(token) do
            {user, _} -> user
            _ -> nil
          end
      end

    # All users can view the home page (no redirects)
    case current_user do
      _ ->
        # All users (admins, vendors, regular users, and non-authenticated) can view products
        if connected?(socket) do
          Phoenix.PubSub.subscribe(MakananSegar.PubSub, "products")
        end

        products = Products.list_public_products()

        {:ok,
         socket
         |> assign(:page_title, "Fresh Products - MakananSegar")
         |> assign(:products, products)
         |> assign(:current_user, current_user)}
    end
  end

  @impl true
  def handle_info({:product_updated, _product}, socket) do
    {:noreply, assign(socket, :products, Products.list_public_products())}
  end

  def handle_info({:product_created, _product}, socket) do
    {:noreply, assign(socket, :products, Products.list_public_products())}
  end

  def handle_info({:product_deleted, _product_id}, socket) do
    {:noreply, assign(socket, :products, Products.list_public_products())}
  end

  defp category_badge_class("fish"), do: "badge-info"
  defp category_badge_class("vegetables"), do: "badge-success"
  defp category_badge_class("fruits"), do: "badge-warning"
  defp category_badge_class(_), do: "badge-ghost"

  defp format_time_until_expiry(expires_at) do
    now = DateTime.now!("Asia/Kuala_Lumpur")
    diff_seconds = DateTime.diff(expires_at, now, :second)

    cond do
      diff_seconds < 3600 ->
        minutes = div(diff_seconds, 60)
        "in #{minutes} min"

      diff_seconds < 86400 ->
        hours = div(diff_seconds, 3600)
        "in #{hours} hr"

      true ->
        days = div(diff_seconds, 86400)
        "in #{days} days"
    end
  end
end

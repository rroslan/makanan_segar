defmodule MakananSegarWeb.Vendor.ProductLive.Index do
  use MakananSegarWeb, :live_view
  on_mount {MakananSegarWeb.UserAuthHooks, :require_vendor_user}

  alias MakananSegar.Products
  alias MakananSegar.Products.Product

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        My Products
        <:subtitle>Manage your product listings</:subtitle>
        <:actions>
          <%= if profile_complete?(@current_scope.user) do %>
            <.link navigate={~p"/vendor/products/new"} class="btn btn-primary">
              <.icon name="hero-plus" class="w-4 h-4 mr-2" /> Add New Product
            </.link>
          <% else %>
            <.link navigate={~p"/vendor/profile"} class="btn btn-warning">
              <.icon name="hero-exclamation-triangle" class="w-4 h-4 mr-2" /> Complete Profile First
            </.link>
          <% end %>
        </:actions>
      </.header>

      <%= unless profile_complete?(@current_scope.user) do %>
        <div class="alert alert-warning shadow-lg mb-6">
          <.icon name="hero-exclamation-triangle" class="w-6 h-6" />
          <div>
            <h3 class="font-bold">Complete Your Profile First</h3>
            <div class="text-xs">
              You need to complete your vendor profile before you can add products.
            </div>
          </div>
          <.link navigate={~p"/vendor/profile"} class="btn btn-sm">
            Complete Profile
          </.link>
        </div>
      <% end %>
      
    <!-- Filter and Search -->
      <div class="flex flex-col md:flex-row gap-4 mb-6">
        <div class="flex-1">
          <.form for={%{}} phx-change="search" class="w-full">
            <div class="join w-full">
              <input
                type="text"
                name="search"
                placeholder="Search products..."
                class="input input-bordered join-item flex-1"
                value={@search}
                phx-debounce="300"
              />
              <button class="btn btn-primary join-item">
                <.icon name="hero-magnifying-glass" class="w-4 h-4" />
              </button>
            </div>
          </.form>
        </div>

        <div class="flex gap-2">
          <select phx-change="filter_status" name="status" class="select select-bordered">
            <option value="all" selected={@filter_status == "all"}>All Products</option>
            <option value="active" selected={@filter_status == "active"}>Active</option>
            <option value="inactive" selected={@filter_status == "inactive"}>Inactive</option>
            <option value="expiring" selected={@filter_status == "expiring"}>Expiring Soon</option>
            <option value="expired" selected={@filter_status == "expired"}>Expired</option>
          </select>

          <select phx-change="filter_category" name="category" class="select select-bordered">
            <option value="all" selected={@filter_category == "all"}>All Categories</option>
            <option value="fish" selected={@filter_category == "fish"}>Fish</option>
            <option value="vegetables" selected={@filter_category == "vegetables"}>Vegetables</option>
            <option value="fruits" selected={@filter_category == "fruits"}>Fruits</option>
          </select>
        </div>
      </div>
      
    <!-- Product Stats -->
      <div class="stats shadow w-full mb-6">
        <div class="stat">
          <div class="stat-title">Total Products</div>
          <div class="stat-value text-primary">{@stats.total}</div>
        </div>
        <div class="stat">
          <div class="stat-title">Active</div>
          <div class="stat-value text-success">{@stats.active}</div>
        </div>
        <div class="stat">
          <div class="stat-title">Expiring Soon</div>
          <div class="stat-value text-warning">{@stats.expiring}</div>
        </div>
        <div class="stat">
          <div class="stat-title">Expired</div>
          <div class="stat-value text-error">{@stats.expired}</div>
        </div>
      </div>

      <%= if @filtered_products == [] do %>
        <div class="text-center py-16">
          <div class="text-6xl mb-8">📦</div>
          <h3 class="text-2xl font-bold mb-4">No products found</h3>
          <p class="text-base-content/70 mb-6">
            <%= if @search != "" || @filter_status != "all" || @filter_category != "all" do %>
              No products match your filters. Try adjusting your search.
            <% else %>
              You haven't added any products yet. Start selling today!
            <% end %>
          </p>
          <%= if profile_complete?(@current_scope.user) do %>
            <.link navigate={~p"/vendor/products/new"} class="btn btn-primary">
              <.icon name="hero-plus" class="w-4 h-4 mr-2" /> Add Your First Product
            </.link>
          <% else %>
            <.link navigate={~p"/vendor/profile"} class="btn btn-warning">
              <.icon name="hero-user" class="w-4 h-4 mr-2" /> Complete Profile First
            </.link>
          <% end %>
        </div>
      <% else %>
        <!-- Product Grid -->
        <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6">
          <%= for product <- @filtered_products do %>
            <div class="card bg-base-100 shadow-xl hover:shadow-2xl transition-shadow">
              <figure class="px-4 pt-4">
                <div class="w-full h-48 rounded-lg overflow-hidden bg-base-200">
                  <%= if product.image do %>
                    <img src={product.image} alt={product.name} class="w-full h-full object-cover" />
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

              <div class="card-body">
                <!-- Product Status -->
                <div class="flex justify-between items-start mb-2">
                  <div class={"badge badge-sm #{category_badge_class(product.category)}"}>
                    {Product.category_display_name(product.category)}
                  </div>
                  <div class={"badge badge-sm #{status_badge_class(product)}"}>
                    {status_text(product)}
                  </div>
                </div>

                <h3 class="card-title text-lg">{product.name}</h3>
                <p class="text-sm text-base-content/70 line-clamp-2">{product.description}</p>
                
    <!-- Price and Expiry -->
                <div class="mt-2">
                  <div class="text-2xl font-bold text-primary">RM {product.price}</div>
                  <div class="text-xs text-base-content/60">
                    Expires: {format_expiry(product.expires_at)}
                  </div>
                </div>
                
    <!-- Active/Inactive Toggle -->
                <div class="form-control mt-2">
                  <label class="label cursor-pointer">
                    <span class="label-text text-sm">
                      {if product.is_active, do: "Active", else: "Inactive"}
                    </span>
                    <input
                      type="checkbox"
                      class="toggle toggle-success toggle-sm"
                      checked={product.is_active}
                      phx-click="toggle_active"
                      phx-value-id={product.id}
                    />
                  </label>
                </div>
                
    <!-- Actions -->
                <div class="card-actions justify-end mt-4">
                  <.link navigate={~p"/vendor/products/#{product.id}"} class="btn btn-sm btn-ghost">
                    <.icon name="hero-eye" class="w-4 h-4" />
                  </.link>
                  <.link
                    navigate={~p"/vendor/products/#{product.id}/edit"}
                    class="btn btn-sm btn-primary"
                  >
                    <.icon name="hero-pencil" class="w-4 h-4" />
                  </.link>
                  <button
                    phx-click="delete"
                    phx-value-id={product.id}
                    data-confirm="Are you sure you want to delete this product?"
                    class="btn btn-sm btn-error"
                  >
                    <.icon name="hero-trash" class="w-4 h-4" />
                  </button>
                </div>
              </div>
            </div>
          <% end %>
        </div>
      <% end %>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Products.subscribe_products(socket.assigns.current_scope)
    end

    products = Products.list_products(socket.assigns.current_scope)
    stats = calculate_stats(products)

    {:ok,
     socket
     |> assign(:page_title, "My Products")
     |> assign(:products, products)
     |> assign(:filtered_products, products)
     |> assign(:stats, stats)
     |> assign(:search, "")
     |> assign(:filter_status, "all")
     |> assign(:filter_category, "all")}
  end

  @impl true
  def handle_event("search", %{"search" => search}, socket) do
    filtered_products =
      filter_products(
        socket.assigns.products,
        search,
        socket.assigns.filter_status,
        socket.assigns.filter_category
      )

    {:noreply,
     socket
     |> assign(:search, search)
     |> assign(:filtered_products, filtered_products)}
  end

  @impl true
  def handle_event("filter_status", %{"status" => status}, socket) do
    filtered_products =
      filter_products(
        socket.assigns.products,
        socket.assigns.search,
        status,
        socket.assigns.filter_category
      )

    {:noreply,
     socket
     |> assign(:filter_status, status)
     |> assign(:filtered_products, filtered_products)}
  end

  @impl true
  def handle_event("filter_category", %{"category" => category}, socket) do
    filtered_products =
      filter_products(
        socket.assigns.products,
        socket.assigns.search,
        socket.assigns.filter_status,
        category
      )

    {:noreply,
     socket
     |> assign(:filter_category, category)
     |> assign(:filtered_products, filtered_products)}
  end

  @impl true
  def handle_event("toggle_active", %{"id" => id}, socket) do
    product = Products.get_product!(socket.assigns.current_scope, id)

    case Products.update_product(
           socket.assigns.current_scope,
           product,
           %{
             is_active: !product.is_active
           },
           nil
         ) do
      {:ok, updated_product} ->
        products = Products.list_products(socket.assigns.current_scope)
        stats = calculate_stats(products)

        filtered_products =
          filter_products(
            products,
            socket.assigns.search,
            socket.assigns.filter_status,
            socket.assigns.filter_category
          )

        {:noreply,
         socket
         |> assign(:products, products)
         |> assign(:filtered_products, filtered_products)
         |> assign(:stats, stats)
         |> put_flash(
           :info,
           "Product #{if updated_product.is_active, do: "activated", else: "deactivated"} successfully"
         )}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to update product status")}
    end
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    product = Products.get_product!(socket.assigns.current_scope, id)

    case Products.delete_product(socket.assigns.current_scope, product) do
      {:ok, _} ->
        products = Products.list_products(socket.assigns.current_scope)
        stats = calculate_stats(products)

        filtered_products =
          filter_products(
            products,
            socket.assigns.search,
            socket.assigns.filter_status,
            socket.assigns.filter_category
          )

        {:noreply,
         socket
         |> assign(:products, products)
         |> assign(:filtered_products, filtered_products)
         |> assign(:stats, stats)
         |> put_flash(:info, "Product deleted successfully")}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to delete product")}
    end
  end

  @impl true
  def handle_info({type, %MakananSegar.Products.Product{}}, socket)
      when type in [:created, :updated, :deleted] do
    products = Products.list_products(socket.assigns.current_scope)
    stats = calculate_stats(products)

    filtered_products =
      filter_products(
        products,
        socket.assigns.search,
        socket.assigns.filter_status,
        socket.assigns.filter_category
      )

    {:noreply,
     socket
     |> assign(:products, products)
     |> assign(:filtered_products, filtered_products)
     |> assign(:stats, stats)}
  end

  defp filter_products(products, search, status, category) do
    products
    |> filter_by_search(search)
    |> filter_by_status(status)
    |> filter_by_category(category)
  end

  defp filter_by_search(products, ""), do: products

  defp filter_by_search(products, search) do
    search = String.downcase(search)

    Enum.filter(products, fn product ->
      String.contains?(String.downcase(product.name), search) ||
        String.contains?(String.downcase(product.description || ""), search)
    end)
  end

  defp filter_by_status(products, "all"), do: products

  defp filter_by_status(products, "active") do
    Enum.filter(products, & &1.is_active)
  end

  defp filter_by_status(products, "inactive") do
    Enum.filter(products, &(!&1.is_active))
  end

  defp filter_by_status(products, "expiring") do
    Enum.filter(products, &Product.expiring_soon?/1)
  end

  defp filter_by_status(products, "expired") do
    Enum.filter(products, &Product.expired?/1)
  end

  defp filter_by_category(products, "all"), do: products

  defp filter_by_category(products, category) do
    Enum.filter(products, &(&1.category == category))
  end

  defp calculate_stats(products) do
    %{
      total: length(products),
      active: Enum.count(products, & &1.is_active),
      expiring: Enum.count(products, &Product.expiring_soon?/1),
      expired: Enum.count(products, &Product.expired?/1)
    }
  end

  defp category_badge_class("fish"), do: "badge-info"
  defp category_badge_class("vegetables"), do: "badge-success"
  defp category_badge_class("fruits"), do: "badge-warning"
  defp category_badge_class(_), do: "badge-ghost"

  defp status_badge_class(product) do
    cond do
      Product.expired?(product) -> "badge-error"
      Product.expiring_soon?(product) -> "badge-warning"
      !product.is_active -> "badge-ghost"
      true -> "badge-success"
    end
  end

  defp status_text(product) do
    cond do
      Product.expired?(product) -> "Expired"
      Product.expiring_soon?(product) -> "Expiring"
      !product.is_active -> "Inactive"
      true -> "Fresh"
    end
  end

  defp format_expiry(expires_at) do
    malaysia_now = DateTime.now!("Asia/Kuala_Lumpur")

    case DateTime.compare(expires_at, malaysia_now) do
      :lt ->
        "Expired"

      :gt ->
        diff = DateTime.diff(expires_at, malaysia_now, :hour)

        cond do
          diff < 1 -> "< 1 hour"
          diff < 24 -> "#{diff} hours"
          diff < 48 -> "Tomorrow"
          true -> Calendar.strftime(expires_at, "%b %d")
        end

      :eq ->
        "Expires now"
    end
  end

  defp profile_complete?(user) do
    user.business_name && user.phone && user.address
  end
end

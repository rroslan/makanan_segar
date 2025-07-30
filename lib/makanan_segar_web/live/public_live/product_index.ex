defmodule MakananSegarWeb.PublicLive.ProductIndex do
  use MakananSegarWeb, :live_view

  alias MakananSegar.Products
  alias MakananSegar.Products.Product

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <div class="bg-base-100">
        <!-- Hero Section -->
        <div class="hero min-h-[40vh] bg-gradient-to-br from-green-50 to-blue-50">
          <div class="hero-content text-center">
            <div class="max-w-3xl">
              <h1 class="text-5xl font-bold mb-6">Fresh Products</h1>
              <p class="text-xl text-base-content/80 mb-8">
                Discover the freshest fish, vegetables, and fruits from local Malaysian vendors
              </p>
              
    <!-- Category Filter -->
              <div class="flex flex-wrap justify-center gap-4 mb-8">
                <.link
                  navigate={~p"/products"}
                  class={"btn #{if @selected_category == "", do: "btn-primary", else: "btn-outline"}"}
                >
                  All Products
                </.link>
                <.link
                  navigate={~p"/products?category=fish"}
                  class={"btn #{if @selected_category == "fish", do: "btn-primary", else: "btn-outline"}"}
                >
                  🐟 Fresh Fish
                </.link>
                <.link
                  navigate={~p"/products?category=vegetables"}
                  class={"btn #{if @selected_category == "vegetables", do: "btn-success", else: "btn-outline"}"}
                >
                  🥬 Vegetables
                </.link>
                <.link
                  navigate={~p"/products?category=fruits"}
                  class={"btn #{if @selected_category == "fruits", do: "btn-warning", else: "btn-outline"}"}
                >
                  🥭 Fruits
                </.link>
              </div>
              
    <!-- Search -->
              <div class="max-w-md mx-auto">
                <.form for={%{}} phx-submit="search" class="join w-full">
                  <input
                    type="text"
                    name="search"
                    placeholder="Search products..."
                    class="input input-bordered join-item flex-1"
                    value={@search_term}
                  />
                  <button type="submit" class="btn btn-primary join-item">
                    <.icon name="hero-magnifying-glass" class="w-4 h-4" />
                  </button>
                </.form>
              </div>
            </div>
          </div>
        </div>
        
    <!-- Products Section -->
        <div class="container mx-auto px-4 py-12">
          <%= if @loading do %>
            <div class="text-center py-12">
              <span class="loading loading-spinner loading-lg"></span>
              <p class="mt-4">Loading fresh products...</p>
            </div>
          <% else %>
            <%= if @products == [] do %>
              <div class="text-center py-16">
                <div class="text-6xl mb-8">🥬</div>
                <h3 class="text-2xl font-bold mb-4">No products found</h3>
                <p class="text-base-content/70 mb-6">
                  <%= if @search_term != "" do %>
                    No products match your search "{@search_term}"
                  <% else %>
                    <%= if @selected_category != "" do %>
                      No {Product.category_display_name(@selected_category) |> String.downcase()} available right now
                    <% else %>
                      No fresh products available at the moment
                    <% end %>
                  <% end %>
                </p>
                <.link navigate={~p"/users/register"} class="btn btn-primary">
                  Become a Vendor
                </.link>
              </div>
            <% else %>
              <!-- Results Header -->
              <div class="flex justify-between items-center mb-8">
                <div>
                  <h2 class="text-3xl font-bold">
                    <%= if @selected_category != "" do %>
                      {Product.category_display_name(@selected_category)}
                    <% else %>
                      All Products
                    <% end %>
                  </h2>
                  <p class="text-base-content/70">
                    Showing {@products_count} fresh {if @products_count == 1,
                      do: "product",
                      else: "products"}
                  </p>
                </div>
                
    <!-- Sort Options -->
                <div class="dropdown dropdown-end">
                  <div tabindex="0" role="button" class="btn btn-outline">
                    <.icon name="hero-bars-3-bottom-left" class="w-4 h-4 mr-2" />
                    Sort by {@sort_display}
                  </div>
                  <ul
                    tabindex="0"
                    class="dropdown-content z-[1] menu p-2 shadow bg-base-100 rounded-box w-52"
                  >
                    <li>
                      <button phx-click="sort_by" phx-value-sort="newest">Newest First</button>
                    </li>
                    <li>
                      <button phx-click="sort_by" phx-value-sort="price_low">
                        Price: Low to High
                      </button>
                    </li>
                    <li>
                      <button phx-click="sort_by" phx-value-sort="price_high">
                        Price: High to Low
                      </button>
                    </li>
                    <li>
                      <button phx-click="sort_by" phx-value-sort="expiring">Expiring Soon</button>
                    </li>
                  </ul>
                </div>
              </div>
              
    <!-- Product Grid -->
              <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6">
                <%= for product <- @products do %>
                  <.product_card product={product} />
                <% end %>
              </div>
            <% end %>
          <% end %>
        </div>
      </div>
    </Layouts.app>
    """
  end

  # Product Card Component
  attr :product, :map, required: true

  defp product_card(assigns) do
    ~H"""
    <div class="card bg-base-100 shadow-xl hover:shadow-2xl transition-shadow group">
      <figure class="px-4 pt-4">
        <div class="w-full h-48 rounded-lg overflow-hidden bg-base-200">
          <%= if @product.image do %>
            <img
              src={@product.image}
              alt={@product.name}
              class="w-full h-full object-cover group-hover:scale-105 transition-transform duration-300"
            />
          <% else %>
            <div class="w-full h-full flex items-center justify-center text-6xl">
              <%= case @product.category do %>
                <% "fish" -> %>
                  🐟
                <% "vegetables" -> %>
                  🥬
                <% "fruits" -> %>
                  🥭
                <% _ -> %>
                  🥬
              <% end %>
            </div>
          <% end %>
        </div>
      </figure>

      <div class="card-body p-4">
        <!-- Category & Freshness Badge -->
        <div class="flex justify-between items-start mb-2">
          <div class={"badge badge-sm #{category_badge_class(@product.category)}"}>
            {Product.category_display_name(@product.category)}
          </div>
          <div class={"badge badge-sm #{freshness_badge_class(@product)}"}>
            {freshness_text(@product)}
          </div>
        </div>

        <h3 class="card-title text-lg mb-2 line-clamp-2">{@product.name}</h3>

        <p class="text-sm text-base-content/70 line-clamp-2 mb-3">
          {@product.description}
        </p>
        
    <!-- Price -->
        <div class="flex items-center justify-between mb-3">
          <div class="text-2xl font-bold text-primary">
            RM {@product.price}
          </div>
          <div class="text-xs text-base-content/60">
            per unit
          </div>
        </div>
        
    <!-- Vendor Info -->
        <div class="border-t pt-3 mt-3">
          <div class="flex items-center gap-3 mb-2">
            <div class="avatar">
              <div class="w-8 h-8 rounded-full">
                <%= if @product.user.profile_image do %>
                  <img
                    src={@product.user.profile_image}
                    alt={@product.user.business_name || @product.user.name}
                  />
                <% else %>
                  <div class="bg-accent text-accent-content w-8 h-8 flex items-center justify-center text-xs">
                    {String.first(
                      @product.user.business_name || @product.user.name || @product.user.email
                    )
                    |> String.upcase()}
                  </div>
                <% end %>
              </div>
            </div>
            <div class="flex-1 min-w-0">
              <h4 class="font-semibold text-sm truncate">
                {@product.user.business_name || @product.user.name || "Vendor"}
              </h4>
              <%= if @product.user.business_type do %>
                <div class="badge badge-xs badge-outline">
                  {String.capitalize(@product.user.business_type)}
                </div>
              <% end %>
            </div>
          </div>

          <%= if @product.user.phone do %>
            <div class="flex items-center gap-1 text-xs text-base-content/60 mb-1">
              <.icon name="hero-phone" class="w-3 h-3" />
              <span>{@product.user.phone}</span>
            </div>
          <% end %>

          <%= if @product.user.business_hours do %>
            <div class="flex items-center gap-1 text-xs text-base-content/60">
              <.icon name="hero-clock" class="w-3 h-3" />
              <span class="truncate">{@product.user.business_hours}</span>
            </div>
          <% end %>
        </div>
        
    <!-- Expiry Info -->
        <div class="text-xs text-base-content/60 mb-4">
          Expires: {format_expiry(@product.expires_at)}
        </div>
        
    <!-- Actions -->
        <div class="card-actions justify-end">
          <.link navigate={~p"/products/#{@product.id}"} class="btn btn-primary btn-sm">
            View Details
          </.link>
        </div>
      </div>
    </div>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      # Subscribe to product updates
      Phoenix.PubSub.subscribe(MakananSegar.PubSub, "products")
    end

    # Load products immediately
    products = Products.list_public_products()

    socket =
      socket
      |> assign(:loading, false)
      |> assign(:products, products)
      |> assign(:products_count, length(products))
      |> assign(:selected_category, "")
      |> assign(:search_term, "")
      |> assign(:sort_by, "newest")
      |> assign(:sort_display, "Newest First")
      |> assign(:page_title, "Fresh Products")

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    category = Map.get(params, "category", "")
    search = Map.get(params, "search", "")

    socket =
      socket
      |> assign(:selected_category, category)
      |> assign(:search_term, search)
      |> assign(:loading, true)

    # Load products asynchronously
    send(self(), :load_products)

    {:noreply, socket}
  end

  @impl true
  def handle_event("search", %{"search" => search_term}, socket) do
    search_params = if search_term != "", do: [search: search_term], else: []

    category_params =
      if socket.assigns.selected_category != "",
        do: [category: socket.assigns.selected_category],
        else: []

    params = search_params ++ category_params

    {:noreply, push_navigate(socket, to: ~p"/products?#{params}")}
  end

  @impl true
  def handle_event("sort_by", %{"sort" => sort_by}, socket) do
    sort_display =
      case sort_by do
        "newest" -> "Newest First"
        "price_low" -> "Price: Low to High"
        "price_high" -> "Price: High to Low"
        "expiring" -> "Expiring Soon"
        _ -> "Newest First"
      end

    socket =
      socket
      |> assign(:sort_by, sort_by)
      |> assign(:sort_display, sort_display)
      |> assign(:loading, true)

    send(self(), :load_products)

    {:noreply, socket}
  end

  @impl true
  def handle_info(:load_products, socket) do
    products = load_filtered_products(socket.assigns)

    socket =
      socket
      |> assign(:products, products)
      |> assign(:products_count, length(products))
      |> assign(:loading, false)

    {:noreply, socket}
  end

  @impl true
  def handle_info({:product_created, _product}, socket) do
    send(self(), :load_products)
    {:noreply, socket}
  end

  @impl true
  def handle_info({:product_updated, _product}, socket) do
    send(self(), :load_products)
    {:noreply, socket}
  end

  @impl true
  def handle_info({:product_deleted, _product}, socket) do
    send(self(), :load_products)
    {:noreply, socket}
  end

  defp load_filtered_products(assigns) do
    products =
      if assigns.selected_category != "" do
        Products.list_products_by_category(assigns.selected_category)
      else
        Products.list_public_products()
      end

    products
    |> filter_by_search(assigns.search_term)
    |> sort_products(assigns.sort_by)
  end

  defp filter_by_search(products, "") do
    products
  end

  defp filter_by_search(products, search_term) do
    search_term = String.downcase(search_term)

    Enum.filter(products, fn product ->
      String.contains?(String.downcase(product.name), search_term) ||
        String.contains?(String.downcase(product.description), search_term) ||
        String.contains?(String.downcase(product.user.name || ""), search_term)
    end)
  end

  defp sort_products(products, "newest") do
    Enum.sort_by(products, & &1.inserted_at, {:desc, DateTime})
  end

  defp sort_products(products, "price_low") do
    Enum.sort_by(products, & &1.price, :asc)
  end

  defp sort_products(products, "price_high") do
    Enum.sort_by(products, & &1.price, :desc)
  end

  defp sort_products(products, "expiring") do
    Enum.sort_by(products, & &1.expires_at, :asc)
  end

  defp sort_products(products, _) do
    products
  end

  defp category_badge_class("fish"), do: "badge-info"
  defp category_badge_class("vegetables"), do: "badge-success"
  defp category_badge_class("fruits"), do: "badge-warning"
  defp category_badge_class(_), do: "badge-ghost"

  defp freshness_badge_class(product) do
    cond do
      Product.expired?(product) -> "badge-error"
      Product.expiring_soon?(product) -> "badge-warning"
      true -> "badge-success"
    end
  end

  defp freshness_text(product) do
    cond do
      Product.expired?(product) -> "Expired"
      Product.expiring_soon?(product) -> "Expiring Soon"
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
          diff < 1 -> "Less than 1 hour"
          diff < 24 -> "#{diff} hours"
          diff < 48 -> "Tomorrow"
          true -> Calendar.strftime(expires_at, "%b %d")
        end

      :eq ->
        "Expires now"
    end
  end
end

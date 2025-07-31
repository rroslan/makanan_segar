defmodule MakananSegarWeb.PublicLive.VendorShow do
  use MakananSegarWeb, :live_view

  alias MakananSegar.Accounts
  alias MakananSegar.Products
  alias MakananSegar.Products.Product

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <div class="bg-base-100">
        <%= if @loading do %>
          <div class="container mx-auto px-4 py-12">
            <div class="text-center py-12">
              <span class="loading loading-spinner loading-lg"></span>
              <p class="mt-4">Loading vendor profile...</p>
            </div>
          </div>
        <% else %>
          <%= if @vendor do %>
            <!-- Breadcrumb -->
            <div class="container mx-auto px-4 py-4">
              <div class="breadcrumbs text-sm">
                <ul>
                  <li><.link navigate={~p"/"}>Home</.link></li>
                  <li><.link navigate={~p"/vendors"}>Vendors</.link></li>
                  <li>{@vendor.name || @vendor.email}</li>
                </ul>
              </div>
            </div>

    <!-- Vendor Profile Header -->
            <div class="bg-gradient-to-br from-green-50 to-blue-50">
              <div class="container mx-auto px-4 py-12">
                <div class="grid grid-cols-1 lg:grid-cols-3 gap-8">
                  <!-- Vendor Avatar -->
                  <div class="lg:col-span-1 text-center lg:text-left">
                    <div class="avatar mb-6">
                      <div class="w-32 h-32 rounded-full mx-auto lg:mx-0">
                        <%= if @vendor.profile_image do %>
                          <img src={@vendor.profile_image} alt={@vendor.name} />
                        <% else %>
                          <div class="bg-primary text-primary-content w-32 h-32 flex items-center justify-center text-4xl font-bold">
                            {String.first(@vendor.name || @vendor.email) |> String.upcase()}
                          </div>
                        <% end %>
                      </div>
                    </div>

                    <div class="badge badge-success mb-4">Verified Vendor</div>

                    <div class="stats stats-vertical lg:stats-horizontal shadow bg-base-100 mb-6">
                      <div class="stat">
                        <div class="stat-title text-xs">Products</div>
                        <div class="stat-value text-lg">{@product_count}</div>
                      </div>
                      <div class="stat">
                        <div class="stat-title text-xs">Member Since</div>
                        <div class="stat-value text-sm">{format_join_date(@vendor.inserted_at)}</div>
                      </div>
                    </div>
                  </div>

    <!-- Vendor Info -->
                  <div class="lg:col-span-2">
                    <h1 class="text-4xl font-bold mb-2">
                      {@vendor.business_name || @vendor.name || "Unnamed Vendor"}
                    </h1>

                    <%= if @vendor.business_type do %>
                      <div class="badge badge-primary badge-lg mb-4">
                        {String.capitalize(@vendor.business_type)} Specialist
                      </div>
                    <% end %>

                    <div class="flex items-center gap-2 mb-4">
                      <.icon name="hero-envelope" class="w-4 h-4 text-base-content/60" />
                      <span class="text-base-content/80">{@vendor.email}</span>
                    </div>

                    <%= if @vendor.phone do %>
                      <div class="flex items-center gap-2 mb-4">
                        <.icon name="hero-phone" class="w-4 h-4 text-base-content/60" />
                        <span class="text-base-content/80">{@vendor.phone}</span>
                      </div>
                    <% end %>

                    <%= if @vendor.business_hours do %>
                      <div class="flex items-center gap-2 mb-4">
                        <.icon name="hero-clock" class="w-4 h-4 text-base-content/60" />
                        <span class="text-base-content/80">{@vendor.business_hours}</span>
                      </div>
                    <% end %>

                    <%= if @vendor.address do %>
                      <div class="flex items-start gap-2 mb-6">
                        <.icon name="hero-map-pin" class="w-4 h-4 text-base-content/60 mt-1" />
                        <span class="text-base-content/80">{@vendor.address}</span>
                      </div>
                    <% end %>

                    <%= if @vendor.website do %>
                      <div class="flex items-center gap-2 mb-6">
                        <.icon name="hero-globe-alt" class="w-4 h-4 text-base-content/60" />
                        <a href={@vendor.website} target="_blank" class="link link-primary">
                          {@vendor.website}
                        </a>
                      </div>
                    <% end %>

                    <%= if @vendor.business_description do %>
                      <div class="mb-6">
                        <h3 class="text-xl font-semibold mb-3">About Our Business</h3>
                        <p class="text-base-content/80 leading-relaxed">
                          {@vendor.business_description}
                        </p>
                      </div>
                    <% end %>

                    <%= if @vendor.business_registration_number do %>
                      <div class="mb-6">
                        <h3 class="text-lg font-semibold mb-2">Business Registration</h3>
                        <div class="flex items-center gap-2">
                          <.icon name="hero-identification" class="w-4 h-4 text-warning" />
                          <span class="text-sm text-base-content/70">
                            SSM: {@vendor.business_registration_number}
                          </span>
                        </div>
                      </div>
                    <% end %>

    <!-- Product Categories -->
                    <%= if @product_categories != [] do %>
                      <div class="mb-6">
                        <h3 class="text-lg font-semibold mb-3">Specialties</h3>
                        <div class="flex flex-wrap gap-2">
                          <%= for category <- @product_categories do %>
                            <div class={"badge badge-lg #{category_badge_class(category)}"}>
                              {category_emoji(category)} {Product.category_display_name(category)}
                            </div>
                          <% end %>
                        </div>
                      </div>
                    <% end %>

    <!-- Contact Actions -->
                    <%= if @current_scope && @current_scope.user do %>
                      <div class="flex flex-wrap gap-2">
                        <a
                          href={"mailto:#{@vendor.email}?subject=Inquiry from MakananSegar"}
                          class="btn btn-primary"
                        >
                          <.icon name="hero-envelope" class="w-4 h-4 mr-2" /> Email
                        </a>
                        <%= if @vendor.phone do %>
                          <a href={"tel:#{@vendor.phone}"} class="btn btn-success">
                            <.icon name="hero-phone" class="w-4 h-4 mr-2" /> Call
                          </a>
                        <% end %>
                        <%= if @vendor.website do %>
                          <a href={@vendor.website} target="_blank" class="btn btn-info">
                            <.icon name="hero-globe-alt" class="w-4 h-4 mr-2" /> Website
                          </a>
                        <% end %>
                      </div>
                    <% else %>
                      <div class="alert alert-info">
                        <.icon name="hero-information-circle" class="w-5 h-5" />
                        <div>
                          <p>Log in to contact this vendor</p>
                          <div class="mt-2">
                            <.link navigate={~p"/users/log-in"} class="btn btn-primary btn-sm mr-2">
                              Log In
                            </.link>
                            <.link navigate={~p"/users/register"} class="btn btn-outline btn-sm">
                              Register
                            </.link>
                          </div>
                        </div>
                      </div>
                    <% end %>
                  </div>
                </div>
              </div>
            </div>

    <!-- Vendor Products -->
            <div class="container mx-auto px-4 py-12">
              <div class="flex justify-between items-center mb-8">
                <div>
                  <h2 class="text-3xl font-bold">
                    Products by {@vendor.business_name || @vendor.name || "this vendor"}
                  </h2>
                  <p class="text-base-content/70">
                    {if @products == [],
                      do: "No products available",
                      else: "#{@product_count} fresh products"}
                  </p>
                </div>

    <!-- Category Filter -->
                <%= if @product_categories != [] do %>
                  <div class="flex flex-wrap gap-2">
                    <button
                      phx-click="filter_category"
                      phx-value-category=""
                      class={"btn btn-sm #{if @selected_category == "", do: "btn-primary", else: "btn-outline"}"}
                    >
                      All
                    </button>
                    <%= for category <- @product_categories do %>
                      <button
                        phx-click="filter_category"
                        phx-value-category={category}
                        class={"btn btn-sm #{if @selected_category == category, do: "btn-primary", else: "btn-outline"}"}
                      >
                        {category_emoji(category)} {String.capitalize(category)}
                      </button>
                    <% end %>
                  </div>
                <% end %>
              </div>

              <%= if @products == [] do %>
                <div class="text-center py-16">
                  <div class="text-6xl mb-8">📦</div>
                  <h3 class="text-2xl font-bold mb-4">No products available</h3>
                  <p class="text-base-content/70">
                    <%= if @selected_category != "" do %>
                      This vendor doesn't have any {String.downcase(
                        Product.category_display_name(@selected_category)
                      )} at the moment.
                    <% else %>
                      This vendor hasn't listed any products yet.
                    <% end %>
                  </p>
                  <.link navigate={~p"/"} class="btn btn-primary mt-4">
                    Browse Other Products
                  </.link>
                </div>
              <% else %>
                <!-- Products Grid -->
                <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6">
                  <%= for product <- @filtered_products do %>
                    <.product_card product={product} />
                  <% end %>
                </div>
              <% end %>
            </div>
          <% else %>
            <!-- Vendor Not Found -->
            <div class="container mx-auto px-4 py-12">
              <div class="text-center py-16">
                <div class="text-6xl mb-8">😕</div>
                <h2 class="text-3xl font-bold mb-4">Vendor Not Found</h2>
                <p class="text-base-content/70 mb-6">
                  The vendor you're looking for doesn't exist or is not verified.
                </p>
                <.link navigate={~p"/vendors"} class="btn btn-primary">
                  Browse All Vendors
                </.link>
              </div>
            </div>
          <% end %>
        <% end %>
      </div>
    </Layouts.app>
    """
  end

  # Product Card Component (similar to the one in product index)
  attr :product, :map, required: true

  defp product_card(assigns) do
    ~H"""
    <div class="card bg-base-100 shadow-xl hover:shadow-2xl transition-shadow group">
      <figure class="px-4 pt-4">
        <div class="w-full h-40 rounded-lg overflow-hidden bg-base-200">
          <%= if @product.image do %>
            <img
              src={@product.image}
              alt={@product.name}
              class="w-full h-full object-cover group-hover:scale-105 transition-transform duration-300"
            />
          <% else %>
            <div class="w-full h-full flex items-center justify-center text-4xl">
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
    {:ok,
     socket
     |> assign(:loading, true)
     |> assign(:vendor, nil)
     |> assign(:products, [])
     |> assign(:filtered_products, [])
     |> assign(:product_count, 0)
     |> assign(:product_categories, [])
     |> assign(:selected_category, "")
     |> assign(:stats, %{})}
  end

  @impl true
  def handle_params(%{"id" => id}, _url, socket) do
    case Integer.parse(id) do
      {vendor_id, ""} ->
        send(self(), {:load_vendor, vendor_id})
        {:noreply, socket}

      _ ->
        {:noreply, assign(socket, :loading, false)}
    end
  end

  @impl true
  def handle_event("filter_category", %{"category" => category}, socket) do
    filtered_products =
      if category == "" do
        socket.assigns.products
      else
        Enum.filter(socket.assigns.products, &(&1.category == category))
      end

    socket =
      socket
      |> assign(:selected_category, category)
      |> assign(:filtered_products, filtered_products)

    {:noreply, socket}
  end

  @impl true
  def handle_info({:load_vendor, vendor_id}, socket) do
    # Subscribe to product updates for real-time updates
    if connected?(socket) do
      Phoenix.PubSub.subscribe(MakananSegar.PubSub, "products")
    end

    try do
      vendor = Accounts.get_user!(vendor_id)

      if vendor.is_vendor do
        # Load vendor's products
        products =
          Products.list_public_products()
          |> Enum.filter(&(&1.user_id == vendor.id))

        product_categories = products |> Enum.map(& &1.category) |> Enum.uniq() |> Enum.sort()

        socket =
          socket
          |> assign(:vendor, vendor)
          |> assign(:products, products)
          |> assign(:filtered_products, products)
          |> assign(:product_count, length(products))
          |> assign(:product_categories, product_categories)
          |> assign(:loading, false)
          |> assign(:page_title, vendor.name || vendor.email)

        {:noreply, socket}
      else
        socket =
          socket
          |> assign(:vendor, nil)
          |> assign(:loading, false)
          |> assign(:page_title, "Vendor Not Found")

        {:noreply, socket}
      end
    rescue
      Ecto.NoResultsError ->
        socket =
          socket
          |> assign(:vendor, nil)
          |> assign(:loading, false)
          |> assign(:page_title, "Vendor Not Found")

        {:noreply, socket}
    end
  end

  @impl true
  def handle_info({:product_created, product}, socket) do
    if socket.assigns.vendor && product.user_id == socket.assigns.vendor.id do
      products = [product | socket.assigns.products]
      categories = Enum.uniq(Enum.map(products, & &1.category))

      filtered_products =
        if socket.assigns.selected_category == "" ||
             product.category == socket.assigns.selected_category do
          [product | socket.assigns.filtered_products]
        else
          socket.assigns.filtered_products
        end

      {:noreply,
       socket
       |> assign(:products, products)
       |> assign(:filtered_products, filtered_products)
       |> assign(:product_count, length(products))
       |> assign(:product_categories, categories)}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_info({:product_updated, product}, socket) do
    if socket.assigns.vendor && product.user_id == socket.assigns.vendor.id do
      products =
        Enum.map(socket.assigns.products, fn p ->
          if p.id == product.id, do: product, else: p
        end)

      filtered_products =
        if socket.assigns.selected_category == "" do
          products
        else
          Enum.filter(products, &(&1.category == socket.assigns.selected_category))
        end

      {:noreply,
       socket
       |> assign(:products, products)
       |> assign(:filtered_products, filtered_products)}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_info({:product_deleted, product_id}, socket) do
    if socket.assigns.vendor do
      products = Enum.reject(socket.assigns.products, &(&1.id == product_id))
      categories = Enum.uniq(Enum.map(products, & &1.category))

      filtered_products =
        if socket.assigns.selected_category == "" do
          products
        else
          Enum.filter(products, &(&1.category == socket.assigns.selected_category))
        end

      {:noreply,
       socket
       |> assign(:products, products)
       |> assign(:filtered_products, filtered_products)
       |> assign(:product_count, length(products))
       |> assign(:product_categories, categories)}
    else
      {:noreply, socket}
    end
  end

  defp category_badge_class("fish"), do: "badge-info"
  defp category_badge_class("vegetables"), do: "badge-success"
  defp category_badge_class("fruits"), do: "badge-warning"
  defp category_badge_class(_), do: "badge-ghost"

  defp category_emoji("fish"), do: "🐟"
  defp category_emoji("vegetables"), do: "🥬"
  defp category_emoji("fruits"), do: "🥭"
  defp category_emoji(_), do: "🥬"

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

  defp format_join_date(datetime) do
    datetime
    |> DateTime.shift_zone!("Asia/Kuala_Lumpur")
    |> Calendar.strftime("%B %Y")
  end
end

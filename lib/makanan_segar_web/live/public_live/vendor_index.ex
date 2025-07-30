defmodule MakananSegarWeb.PublicLive.VendorIndex do
  use MakananSegarWeb, :live_view

  alias MakananSegar.Accounts
  alias MakananSegar.Products

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <div class="bg-base-100">
        <!-- Hero Section -->
        <div class="hero min-h-[40vh] bg-gradient-to-br from-green-50 to-blue-50">
          <div class="hero-content text-center">
            <div class="max-w-3xl">
              <h1 class="text-5xl font-bold mb-6">Malaysian Vendors</h1>
              <p class="text-xl text-base-content/80 mb-8">
                Discover trusted local vendors selling the freshest produce across Malaysia
              </p>
              
    <!-- Search -->
              <div class="max-w-md mx-auto">
                <div class="join w-full">
                  <input
                    type="text"
                    placeholder="Search vendors..."
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
        
    <!-- Vendors Section -->
        <div class="container mx-auto px-4 py-12">
          <%= if @loading do %>
            <div class="text-center py-12">
              <span class="loading loading-spinner loading-lg"></span>
              <p class="mt-4">Loading vendors...</p>
            </div>
          <% else %>
            <%= if @vendors == [] do %>
              <div class="text-center py-16">
                <div class="text-6xl mb-8">🏪</div>
                <h3 class="text-2xl font-bold mb-4">No vendors found</h3>
                <p class="text-base-content/70 mb-6">
                  <%= if @search_term != "" do %>
                    No vendors match your search "{@search_term}"
                  <% else %>
                    No vendors available at the moment
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
                  <h2 class="text-3xl font-bold">Local Vendors</h2>
                  <p class="text-base-content/70">
                    Showing {@vendors_count} verified {if @vendors_count == 1,
                      do: "vendor",
                      else: "vendors"}
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
                      <button phx-click="sort_by" phx-value-sort="name">Name A-Z</button>
                    </li>
                    <li>
                      <button phx-click="sort_by" phx-value-sort="products">Most Products</button>
                    </li>
                  </ul>
                </div>
              </div>
              
    <!-- Vendor Grid -->
              <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6">
                <%= for vendor <- @vendors do %>
                  <.vendor_card vendor={vendor} />
                <% end %>
              </div>
            <% end %>
          <% end %>
        </div>
      </div>
    </Layouts.app>
    """
  end

  # Vendor Card Component
  attr :vendor, :map, required: true

  defp vendor_card(assigns) do
    ~H"""
    <div class="card bg-base-100 shadow-xl hover:shadow-2xl transition-shadow group">
      <figure class="px-4 pt-4">
        <div class="w-full h-32 rounded-lg overflow-hidden bg-base-200">
          <%= if @vendor.profile_image do %>
            <img
              src={@vendor.profile_image}
              alt={@vendor.business_name || @vendor.name}
              class="w-full h-full object-cover group-hover:scale-105 transition-transform duration-300"
            />
          <% else %>
            <div class="w-full h-full flex items-center justify-center">
              <div class="w-20 h-20 rounded-full bg-primary text-primary-content flex items-center justify-center text-2xl font-bold">
                {String.first(@vendor.business_name || @vendor.name || @vendor.email)
                |> String.upcase()}
              </div>
            </div>
          <% end %>
        </div>
      </figure>

      <div class="card-body p-4">
        <!-- Vendor Badge -->
        <div class="flex justify-between items-start mb-2">
          <div class="badge badge-success badge-sm">Verified Vendor</div>
          <div class="badge badge-ghost badge-sm">
            {Enum.count(@vendor.products)} products
          </div>
        </div>

        <h3 class="card-title text-lg mb-2">
          {@vendor.business_name || @vendor.name || "Unnamed Vendor"}
        </h3>

        <%= if @vendor.business_type do %>
          <div class="badge badge-primary badge-xs mb-2">
            {String.capitalize(@vendor.business_type)} Specialist
          </div>
        <% end %>

        <p class="text-sm text-base-content/70 mb-2">
          {@vendor.email}
        </p>

        <%= if @vendor.business_description do %>
          <p class="text-sm text-base-content/60 line-clamp-2 mb-3">
            {@vendor.business_description}
          </p>
        <% end %>

        <%= if @vendor.phone do %>
          <div class="flex items-center gap-1 text-xs text-base-content/60 mb-2">
            <.icon name="hero-phone" class="w-3 h-3" />
            <span>{@vendor.phone}</span>
          </div>
        <% end %>

        <%= if @vendor.business_hours do %>
          <div class="flex items-center gap-1 text-xs text-base-content/60 mb-2">
            <.icon name="hero-clock" class="w-3 h-3" />
            <span class="line-clamp-1">{@vendor.business_hours}</span>
          </div>
        <% end %>

        <%= if @vendor.address do %>
          <div class="flex items-center gap-1 text-xs text-base-content/60 mb-3">
            <.icon name="hero-map-pin" class="w-3 h-3" />
            <span class="line-clamp-1">{@vendor.address}</span>
          </div>
        <% end %>
        
    <!-- Product Categories -->
        <%= if @vendor.product_categories != [] do %>
          <div class="flex flex-wrap gap-1 mb-3">
            <%= for category <- @vendor.product_categories do %>
              <div class={"badge badge-xs #{category_badge_class(category)}"}>
                {category_emoji(category)} {String.capitalize(category)}
              </div>
            <% end %>
          </div>
        <% end %>
        
    <!-- Join Date -->
        <div class="text-xs text-base-content/50 mb-4">
          Vendor since {format_join_date(@vendor.inserted_at)}
        </div>
        
    <!-- Actions -->
        <div class="card-actions justify-end">
          <.link navigate={~p"/vendors/#{@vendor.id}"} class="btn btn-primary btn-sm">
            View Profile
          </.link>
        </div>
      </div>
    </div>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      # Subscribe to vendor updates
      Phoenix.PubSub.subscribe(MakananSegar.PubSub, "vendors")
    end

    socket =
      socket
      |> assign(:loading, true)
      |> assign(:vendors, [])
      |> assign(:vendors_count, 0)
      |> assign(:search_term, "")
      |> assign(:sort_by, "newest")
      |> assign(:sort_display, "Newest First")
      |> assign(:page_title, "Malaysian Vendors")

    # Load vendors asynchronously
    send(self(), :load_vendors)

    {:ok, socket}
  end

  @impl true
  def handle_event("search", %{"value" => search_term}, socket) do
    socket =
      socket
      |> assign(:search_term, search_term)
      |> assign(:loading, true)

    send(self(), :load_vendors)

    {:noreply, socket}
  end

  @impl true
  def handle_event("sort_by", %{"sort" => sort_by}, socket) do
    sort_display =
      case sort_by do
        "newest" -> "Newest First"
        "name" -> "Name A-Z"
        "products" -> "Most Products"
        _ -> "Newest First"
      end

    socket =
      socket
      |> assign(:sort_by, sort_by)
      |> assign(:sort_display, sort_display)
      |> assign(:loading, true)

    send(self(), :load_vendors)

    {:noreply, socket}
  end

  @impl true
  def handle_info(:load_vendors, socket) do
    vendors = load_filtered_vendors(socket.assigns)

    socket =
      socket
      |> assign(:vendors, vendors)
      |> assign(:vendors_count, length(vendors))
      |> assign(:loading, false)

    {:noreply, socket}
  end

  @impl true
  def handle_info({:vendor_updated, _vendor}, socket) do
    send(self(), :load_vendors)
    {:noreply, socket}
  end

  defp load_filtered_vendors(assigns) do
    vendors = Accounts.list_vendors()

    # Get products for each vendor and add them to the vendor struct
    vendors_with_products =
      Enum.map(vendors, fn vendor ->
        products = Products.list_public_products() |> Enum.filter(&(&1.user_id == vendor.id))
        product_categories = products |> Enum.map(& &1.category) |> Enum.uniq()

        vendor
        |> Map.put(:products, products)
        |> Map.put(:product_categories, product_categories)
      end)

    vendors_with_products
    |> filter_by_search(assigns.search_term)
    |> sort_vendors(assigns.sort_by)
  end

  defp filter_by_search(vendors, "") do
    vendors
  end

  defp filter_by_search(vendors, search_term) do
    search_term = String.downcase(search_term)

    Enum.filter(vendors, fn vendor ->
      String.contains?(String.downcase(vendor.business_name || ""), search_term) ||
        String.contains?(String.downcase(vendor.name || ""), search_term) ||
        String.contains?(String.downcase(vendor.email), search_term) ||
        String.contains?(String.downcase(vendor.business_description || ""), search_term) ||
        String.contains?(String.downcase(vendor.address || ""), search_term)
    end)
  end

  defp sort_vendors(vendors, "newest") do
    Enum.sort_by(vendors, & &1.inserted_at, {:desc, DateTime})
  end

  defp sort_vendors(vendors, "name") do
    Enum.sort_by(vendors, fn vendor ->
      String.downcase(vendor.business_name || vendor.name || vendor.email)
    end)
  end

  defp sort_vendors(vendors, "products") do
    Enum.sort_by(vendors, &length(&1.products), :desc)
  end

  defp sort_vendors(vendors, _) do
    vendors
  end

  defp category_badge_class("fish"), do: "badge-info"
  defp category_badge_class("vegetables"), do: "badge-success"
  defp category_badge_class("fruits"), do: "badge-warning"
  defp category_badge_class(_), do: "badge-ghost"

  defp category_emoji("fish"), do: "🐟"
  defp category_emoji("vegetables"), do: "🥬"
  defp category_emoji("fruits"), do: "🥭"
  defp category_emoji(_), do: "🥬"

  defp format_join_date(datetime) do
    datetime
    |> DateTime.shift_zone!("Asia/Kuala_Lumpur")
    |> Calendar.strftime("%B %Y")
  end
end

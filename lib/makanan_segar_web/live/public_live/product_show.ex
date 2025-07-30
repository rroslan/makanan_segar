defmodule MakananSegarWeb.PublicLive.ProductShow do
  use MakananSegarWeb, :live_view

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
              <p class="mt-4">Loading product details...</p>
            </div>
          </div>
        <% else %>
          <%= if @product do %>
            <!-- Breadcrumb -->
            <div class="container mx-auto px-4 py-4">
              <div class="breadcrumbs text-sm">
                <ul>
                  <li><.link navigate={~p"/"}>Home</.link></li>
                  <li><.link navigate={~p"/products"}>Products</.link></li>
                  <li>
                    <.link navigate={~p"/products?category=#{@product.category}"}>
                      {Product.category_display_name(@product.category)}
                    </.link>
                  </li>
                  <li>{@product.name}</li>
                </ul>
              </div>
            </div>
            
    <!-- Product Details -->
            <div class="container mx-auto px-4 pb-12">
              <div class="grid grid-cols-1 lg:grid-cols-2 gap-12">
                <!-- Product Image -->
                <div class="space-y-4">
                  <div class="w-full h-96 rounded-lg overflow-hidden bg-base-200 shadow-lg">
                    <%= if @product.image do %>
                      <img
                        src={@product.image}
                        alt={@product.name}
                        class="w-full h-full object-cover"
                      />
                    <% else %>
                      <div class="w-full h-full flex items-center justify-center">
                        <div class="text-center">
                          <div class="text-9xl mb-4">
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
                          <p class="text-base-content/50">No image available</p>
                        </div>
                      </div>
                    <% end %>
                  </div>
                  
    <!-- Freshness Alert -->
                  <div class={"alert #{freshness_alert_class(@product)}"}>
                    <.icon name={freshness_icon(@product)} class="w-5 h-5" />
                    <div>
                      <h4 class="font-semibold">{freshness_title(@product)}</h4>
                      <p class="text-sm">{freshness_message(@product)}</p>
                    </div>
                  </div>
                </div>
                
    <!-- Product Info -->
                <div class="space-y-6">
                  <!-- Category Badge -->
                  <div class={"badge badge-lg #{category_badge_class(@product.category)}"}>
                    {Product.category_display_name(@product.category)}
                  </div>
                  
    <!-- Product Name & Price -->
                  <div>
                    <h1 class="text-4xl font-bold mb-4">{@product.name}</h1>
                    <div class="flex items-baseline gap-4 mb-6">
                      <span class="text-5xl font-bold text-primary">RM {@product.price}</span>
                      <span class="text-base-content/60">per unit</span>
                    </div>
                  </div>
                  
    <!-- Description -->
                  <div>
                    <h3 class="text-xl font-semibold mb-3">Description</h3>
                    <p class="text-base-content/80 leading-relaxed">{@product.description}</p>
                  </div>
                  
    <!-- Vendor Information -->
                  <div class="card bg-base-200 shadow-sm">
                    <div class="card-body">
                      <h3 class="card-title text-lg mb-4">
                        <.icon name="hero-building-storefront" class="w-5 h-5" /> Vendor Profile
                      </h3>
                      
    <!-- Vendor Header -->
                      <div class="flex items-center gap-4 mb-4">
                        <div class="avatar">
                          <div class="w-16 h-16 rounded-full">
                            <%= if @product.user.profile_image do %>
                              <img
                                src={@product.user.profile_image}
                                alt={@product.user.business_name || @product.user.name}
                              />
                            <% else %>
                              <div class="bg-accent text-accent-content w-16 h-16 flex items-center justify-center text-lg">
                                {String.first(
                                  @product.user.business_name || @product.user.name ||
                                    @product.user.email
                                )
                                |> String.upcase()}
                              </div>
                            <% end %>
                          </div>
                        </div>
                        <div class="flex-1">
                          <h4 class="font-bold text-lg">
                            {@product.user.business_name || @product.user.name || "Unnamed Vendor"}
                          </h4>
                          <%= if @product.user.business_type do %>
                            <div class="badge badge-primary badge-sm">
                              {String.capitalize(@product.user.business_type)} Vendor
                            </div>
                          <% else %>
                            <%= if @product.user.is_vendor do %>
                              <div class="badge badge-success badge-sm">Verified Vendor</div>
                            <% end %>
                          <% end %>
                          <p class="text-sm text-base-content/70 mt-1">{@product.user.email}</p>
                        </div>
                      </div>
                      
    <!-- Business Description -->
                      <%= if @product.user.business_description do %>
                        <div class="mb-4">
                          <p class="text-sm text-base-content/80">
                            {@product.user.business_description}
                          </p>
                        </div>
                      <% end %>
                      
    <!-- Business Details Grid -->
                      <div class="grid grid-cols-1 md:grid-cols-2 gap-3 mb-4">
                        <%= if @product.user.phone do %>
                          <div class="flex items-center gap-2 text-sm">
                            <.icon name="hero-phone" class="w-4 h-4 text-success" />
                            <span>{@product.user.phone}</span>
                          </div>
                        <% end %>

                        <%= if @product.user.business_hours do %>
                          <div class="flex items-center gap-2 text-sm">
                            <.icon name="hero-clock" class="w-4 h-4 text-info" />
                            <span>{@product.user.business_hours}</span>
                          </div>
                        <% end %>

                        <%= if @product.user.website do %>
                          <div class="flex items-center gap-2 text-sm">
                            <.icon name="hero-globe-alt" class="w-4 h-4 text-primary" />
                            <a href={@product.user.website} target="_blank" class="link link-primary">
                              Website
                            </a>
                          </div>
                        <% end %>

                        <%= if @product.user.business_registration_number do %>
                          <div class="flex items-center gap-2 text-sm">
                            <.icon name="hero-identification" class="w-4 h-4 text-warning" />
                            <span>SSM: {@product.user.business_registration_number}</span>
                          </div>
                        <% end %>
                      </div>
                      
    <!-- Vendor Stats -->
                      <%= if @vendor_stats do %>
                        <div class="mb-4">
                          <h5 class="font-semibold text-sm mb-2">Vendor Statistics</h5>
                          <div class="stats stats-horizontal shadow-sm bg-base-100 w-full">
                            <div class="stat py-2 px-3">
                              <div class="stat-title text-xs">Products</div>
                              <div class="stat-value text-lg text-primary">
                                {@vendor_stats.total_products}
                              </div>
                            </div>
                            <div class="stat py-2 px-3">
                              <div class="stat-title text-xs">Active</div>
                              <div class="stat-value text-lg text-success">
                                {@vendor_stats.active_products}
                              </div>
                            </div>
                            <div class="stat py-2 px-3">
                              <div class="stat-title text-xs">Fresh</div>
                              <div class="stat-value text-lg text-info">
                                {@vendor_stats.total_products - @vendor_stats.expired_products}
                              </div>
                            </div>
                          </div>
                        </div>
                      <% end %>
                      
    <!-- Actions -->
                      <div class="flex gap-2">
                        <%= if @product.user.website do %>
                          <a
                            href={@product.user.website}
                            target="_blank"
                            class="btn btn-primary btn-sm"
                          >
                            <.icon name="hero-globe-alt" class="w-4 h-4" />
                          </a>
                        <% end %>
                      </div>
                    </div>
                  </div>
                  
    <!-- Product Details -->
                  <div class="space-y-4">
                    <h3 class="text-xl font-semibold">Product Details</h3>

                    <div class="grid grid-cols-2 gap-4">
                      <div class="stat bg-base-200 rounded-lg">
                        <div class="stat-title text-xs">Listed On</div>
                        <div class="stat-value text-sm">{format_date(@product.inserted_at)}</div>
                      </div>

                      <div class="stat bg-base-200 rounded-lg">
                        <div class="stat-title text-xs">Expires</div>
                        <div class="stat-value text-sm">{format_date(@product.expires_at)}</div>
                      </div>
                    </div>

                    <div class="stat bg-base-200 rounded-lg">
                      <div class="stat-title text-xs">Remaining Freshness</div>
                      <div class="stat-value text-lg">{time_until_expiry(@product.expires_at)}</div>
                    </div>
                  </div>
                  
    <!-- Contact Actions -->
                  <div class="space-y-4">
                    <h3 class="text-xl font-semibold">Interested in this product?</h3>

                    <%= if assigns[:current_user] do %>
                      <div class="space-y-2">
                        <p class="text-sm text-base-content/70">
                          Contact the vendor directly to arrange purchase and pickup.
                        </p>
                        <div class="flex gap-2">
                          <a
                            href={"mailto:#{@product.user.email}?subject=Interested in #{@product.name}"}
                            class="btn btn-primary"
                          >
                            <.icon name="hero-envelope" class="w-4 h-4 mr-2" /> Email Vendor
                          </a>
                          <%= if @product.user.phone do %>
                            <a href={"tel:#{@product.user.phone}"} class="btn btn-success">
                              <.icon name="hero-phone" class="w-4 h-4 mr-2" /> Call Vendor
                            </a>
                          <% end %>
                        </div>
                      </div>
                    <% else %>
                      <div class="alert alert-info">
                        <.icon name="hero-information-circle" class="w-5 h-5" />
                        <div>
                          <p>Please log in to contact the vendor</p>
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
              
    <!-- Related Products -->
              <%= if @related_products != [] do %>
                <div class="mt-16">
                  <h2 class="text-3xl font-bold mb-8">More from this vendor</h2>

                  <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6">
                    <%= for product <- @related_products do %>
                      <div class="card bg-base-100 shadow-lg hover:shadow-xl transition-shadow">
                        <figure class="px-4 pt-4">
                          <div class="w-full h-32 rounded-lg overflow-hidden bg-base-200">
                            <%= if product.image do %>
                              <img
                                src={product.image}
                                alt={product.name}
                                class="w-full h-full object-cover"
                              />
                            <% else %>
                              <div class="w-full h-full flex items-center justify-center text-3xl">
                                <%= case product.category do %>
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
                          <h3 class="card-title text-sm">{product.name}</h3>
                          <p class="text-primary font-bold">RM {product.price}</p>

                          <div class="card-actions justify-end mt-2">
                            <.link
                              navigate={~p"/products/#{product.id}"}
                              class="btn btn-primary btn-xs"
                            >
                              View
                            </.link>
                          </div>
                        </div>
                      </div>
                    <% end %>
                  </div>
                </div>
              <% end %>
            </div>
          <% else %>
            <!-- Product Not Found -->
            <div class="container mx-auto px-4 py-12">
              <div class="text-center py-16">
                <div class="text-6xl mb-8">😕</div>
                <h2 class="text-3xl font-bold mb-4">Product Not Found</h2>
                <p class="text-base-content/70 mb-6">
                  The product you're looking for doesn't exist or may have expired.
                </p>
                <.link navigate={~p"/products"} class="btn btn-primary">
                  Browse All Products
                </.link>
              </div>
            </div>
          <% end %>
        <% end %>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:loading, true)
     |> assign(:product, nil)
     |> assign(:related_products, [])
     |> assign(:vendor_stats, nil)}
  end

  @impl true
  def handle_params(%{"id" => id}, _url, socket) do
    case Integer.parse(id) do
      {product_id, ""} ->
        send(self(), {:load_product, product_id})
        {:noreply, socket}

      _ ->
        {:noreply, assign(socket, :loading, false)}
    end
  end

  @impl true
  def handle_info({:load_product, product_id}, socket) do
    try do
      product = Products.get_public_product!(product_id)

      # Load related products from the same vendor (excluding current product)
      related_products =
        Products.list_public_products()
        |> Enum.filter(fn p -> p.user_id == product.user_id && p.id != product.id end)
        |> Enum.take(4)

      # Load vendor stats
      vendor_stats = get_vendor_stats_for_user(product.user)

      socket =
        socket
        |> assign(:product, product)
        |> assign(:related_products, related_products)
        |> assign(:vendor_stats, vendor_stats)
        |> assign(:loading, false)
        |> assign(:page_title, product.name)

      {:noreply, socket}
    rescue
      Ecto.NoResultsError ->
        socket =
          socket
          |> assign(:product, nil)
          |> assign(:loading, false)
          |> assign(:page_title, "Product Not Found")

        {:noreply, socket}
    end
  end

  defp get_vendor_stats_for_user(user) do
    # Get all products for this vendor
    all_products = Products.list_public_products()
    vendor_products = Enum.filter(all_products, &(&1.user_id == user.id))

    total_products = length(vendor_products)
    active_products = Enum.count(vendor_products, & &1.is_active)
    expired_products = Enum.count(vendor_products, &Product.expired?/1)
    expiring_soon = Enum.count(vendor_products, &Product.expiring_soon?/1)

    %{
      total_products: total_products,
      active_products: active_products,
      expired_products: expired_products,
      expiring_soon: expiring_soon
    }
  end

  defp category_badge_class("fish"), do: "badge-info"
  defp category_badge_class("vegetables"), do: "badge-success"
  defp category_badge_class("fruits"), do: "badge-warning"
  defp category_badge_class(_), do: "badge-ghost"

  defp freshness_alert_class(product) do
    cond do
      Product.expired?(product) -> "alert-error"
      Product.expiring_soon?(product) -> "alert-warning"
      true -> "alert-success"
    end
  end

  defp freshness_icon(product) do
    cond do
      Product.expired?(product) -> "hero-x-circle"
      Product.expiring_soon?(product) -> "hero-exclamation-triangle"
      true -> "hero-check-circle"
    end
  end

  defp freshness_title(product) do
    cond do
      Product.expired?(product) -> "Product Expired"
      Product.expiring_soon?(product) -> "Expiring Soon"
      true -> "Fresh & Available"
    end
  end

  defp freshness_message(product) do
    cond do
      Product.expired?(product) ->
        "This product has expired and is no longer fresh."

      Product.expiring_soon?(product) ->
        "This product is expiring within 24 hours. Contact vendor quickly!"

      true ->
        "This product is fresh and ready for purchase."
    end
  end

  defp format_date(datetime) do
    datetime
    |> DateTime.shift_zone!("Asia/Kuala_Lumpur")
    |> Calendar.strftime("%B %d, %Y at %I:%M %p")
  end

  defp time_until_expiry(expires_at) do
    malaysia_now = DateTime.now!("Asia/Kuala_Lumpur")

    case DateTime.compare(expires_at, malaysia_now) do
      :lt ->
        "Expired"

      :gt ->
        diff_seconds = DateTime.diff(expires_at, malaysia_now, :second)

        cond do
          diff_seconds < 3600 ->
            minutes = div(diff_seconds, 60)
            "#{minutes} minutes"

          diff_seconds < 86400 ->
            hours = div(diff_seconds, 3600)
            "#{hours} hours"

          true ->
            days = div(diff_seconds, 86400)
            "#{days} days"
        end

      :eq ->
        "Expires now"
    end
  end
end

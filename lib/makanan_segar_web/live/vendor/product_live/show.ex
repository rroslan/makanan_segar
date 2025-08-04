defmodule MakananSegarWeb.Vendor.ProductLive.Show do
  use MakananSegarWeb, :live_view
  on_mount {MakananSegarWeb.UserAuthHooks, :require_vendor_user}

  alias MakananSegar.Products
  alias MakananSegar.Products.Product

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        Product Details
        <:subtitle>View and manage your product</:subtitle>
        <:actions>
          <.link navigate={~p"/vendor/products"} class="btn btn-ghost">
            <.icon name="hero-arrow-left" class="w-4 h-4 mr-2" /> Back to Products
          </.link>
          <.link navigate={~p"/vendor/products/#{@product}/edit"} class="btn btn-primary">
            <.icon name="hero-pencil-square" class="w-4 h-4 mr-2" /> Edit Product
          </.link>
        </:actions>
      </.header>

      <div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
        <!-- Product Image and Status -->
        <div class="lg:col-span-1">
          <div class="card bg-base-100 shadow-xl">
            <figure class="px-6 pt-6">
              <div class="w-full h-64 rounded-lg overflow-hidden bg-base-200">
                <%= if @product.image do %>
                  <img src={@product.image} alt={@product.name} class="w-full h-full object-cover" />
                <% else %>
                  <div class="w-full h-full flex items-center justify-center text-8xl">
                    <%= case @product.category do %>
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
              <div class="flex justify-between items-center mb-4">
                <div class={"badge badge-lg #{category_badge_class(@product.category)}"}>
                  {Product.category_display_name(@product.category)}
                </div>
                <div class={"badge badge-lg #{status_badge_class(@product)}"}>
                  {status_text(@product)}
                </div>
              </div>
              
    <!-- Active/Inactive Toggle -->
              <div class="form-control">
                <label class="label cursor-pointer">
                  <span class="label-text">Product Status</span>
                  <input
                    type="checkbox"
                    class="toggle toggle-success"
                    checked={@product.is_active}
                    phx-click="toggle_active"
                  />
                </label>
                <p class="text-sm text-base-content/60 mt-1">
                  {if @product.is_active,
                    do: "Product is visible to customers",
                    else: "Product is hidden from customers"}
                </p>
              </div>
              
    <!-- Quick Actions -->
              <div class="mt-6 space-y-2">
                <.link
                  navigate={~p"/vendor/products/#{@product}/edit"}
                  class="btn btn-primary btn-block"
                >
                  <.icon name="hero-pencil" class="w-4 h-4 mr-2" /> Edit Product
                </.link>
                <button
                  phx-click="delete"
                  data-confirm="Are you sure you want to delete this product? This action cannot be undone."
                  class="btn btn-error btn-outline btn-block"
                >
                  <.icon name="hero-trash" class="w-4 h-4 mr-2" /> Delete Product
                </button>
              </div>
            </div>
          </div>
        </div>
        
    <!-- Product Details -->
        <div class="lg:col-span-2">
          <div class="card bg-base-100 shadow-xl">
            <div class="card-body">
              <h2 class="card-title text-3xl">{@product.name}</h2>
              
    <!-- Price -->
              <div class="mt-4">
                <div class="text-4xl font-bold text-primary">RM {@product.price}</div>
                <p class="text-sm text-base-content/60">per unit</p>
              </div>
              
    <!-- Description -->
              <div class="mt-6">
                <h3 class="text-lg font-semibold mb-2">Description</h3>
                <p class="text-base-content/80 whitespace-pre-wrap">{@product.description}</p>
              </div>
              
    <!-- Product Information Grid -->
              <div class="mt-6 grid grid-cols-1 md:grid-cols-2 gap-4">
                <div class="bg-base-200 rounded-lg p-4">
                  <h4 class="font-semibold text-sm mb-1">Category</h4>
                  <p class="text-base-content/80">
                    {Product.category_display_name(@product.category)}
                  </p>
                </div>

                <div class="bg-base-200 rounded-lg p-4">
                  <h4 class="font-semibold text-sm mb-1">Status</h4>
                  <p class="text-base-content/80">
                    {if @product.is_active, do: "Active", else: "Inactive"}
                  </p>
                </div>

                <div class="bg-base-200 rounded-lg p-4">
                  <h4 class="font-semibold text-sm mb-1">Listed On</h4>
                  <p class="text-base-content/80">
                    {format_datetime(@product.inserted_at)}
                  </p>
                </div>

                <div class="bg-base-200 rounded-lg p-4">
                  <h4 class="font-semibold text-sm mb-1">Last Updated</h4>
                  <p class="text-base-content/80">
                    {format_datetime(@product.updated_at)}
                  </p>
                </div>
              </div>
              
    <!-- Expiry Information -->
              <div class="mt-6">
                <h3 class="text-lg font-semibold mb-2">Expiry Information</h3>
                <div class={"alert #{expiry_alert_class(@product)}"}>
                  <.icon name={expiry_icon(@product)} class="w-5 h-5" />
                  <div>
                    <h4 class="font-semibold">{expiry_status(@product)}</h4>
                    <p class="text-sm">
                      Expires on: {format_datetime(@product.expires_at)} ({time_until_expiry(
                        @product.expires_at
                      )})
                    </p>
                  </div>
                </div>
              </div>
              
    <!-- Product ID -->
              <div class="mt-6 text-sm text-base-content/50">
                Product ID: {@product.id}
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
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    product = Products.get_product!(socket.assigns.current_scope, id)

    {:noreply,
     socket
     |> assign(:page_title, product.name)
     |> assign(:product, product)}
  end

  @impl true
  def handle_event("toggle_active", _, socket) do
    product = socket.assigns.product

    case Products.update_product(
           socket.assigns.current_scope,
           product,
           %{
             is_active: !product.is_active
           },
           nil
         ) do
      {:ok, updated_product} ->
        {:noreply,
         socket
         |> assign(:product, updated_product)
         |> put_flash(
           :info,
           "Product #{if updated_product.is_active, do: "activated", else: "deactivated"} successfully"
         )}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to update product status")}
    end
  end

  @impl true
  def handle_event("delete", _, socket) do
    product = socket.assigns.product

    case Products.delete_product(socket.assigns.current_scope, product) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, "Product deleted successfully")
         |> push_navigate(to: ~p"/vendor/products")}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to delete product")}
    end
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
      Product.expiring_soon?(product) -> "Expiring Soon"
      !product.is_active -> "Inactive"
      true -> "Fresh"
    end
  end

  defp expiry_alert_class(product) do
    cond do
      Product.expired?(product) -> "alert-error"
      Product.expiring_soon?(product) -> "alert-warning"
      true -> "alert-success"
    end
  end

  defp expiry_icon(product) do
    cond do
      Product.expired?(product) -> "hero-x-circle"
      Product.expiring_soon?(product) -> "hero-exclamation-triangle"
      true -> "hero-check-circle"
    end
  end

  defp expiry_status(product) do
    cond do
      Product.expired?(product) -> "Product Expired"
      Product.expiring_soon?(product) -> "Expiring Soon"
      true -> "Fresh Product"
    end
  end

  defp format_datetime(datetime) do
    datetime
    |> DateTime.shift_zone!("Asia/Kuala_Lumpur")
    |> Calendar.strftime("%B %d, %Y at %I:%M %p MYT")
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
            "#{minutes} minutes remaining"

          diff_seconds < 86400 ->
            hours = div(diff_seconds, 3600)
            "#{hours} hours remaining"

          true ->
            days = div(diff_seconds, 86400)
            "#{days} days remaining"
        end

      :eq ->
        "Expires now"
    end
  end
end

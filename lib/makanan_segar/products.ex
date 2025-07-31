defmodule MakananSegar.Products do
  @moduledoc """
  The Products context.
  """

  import Ecto.Query, warn: false
  alias MakananSegar.Repo

  alias MakananSegar.Products.Product
  alias MakananSegar.Accounts.Scope
  alias MakananSegar.Workers.ProductExpiryWorker

  @doc """
  Subscribes to scoped notifications about any product changes.

  The broadcasted messages match the pattern:

    * {:created, %Product{}}
    * {:updated, %Product{}}
    * {:deleted, %Product{}}

  """
  def subscribe_products(%Scope{} = scope) do
    key = scope.user.id

    Phoenix.PubSub.subscribe(MakananSegar.PubSub, "user:#{key}:products")
  end

  defp broadcast(%Scope{} = scope, message) do
    key = scope.user.id

    Phoenix.PubSub.broadcast(MakananSegar.PubSub, "user:#{key}:products", message)

    # Also broadcast to public channel for real-time updates on home page
    case message do
      {:created, product} ->
        Phoenix.PubSub.broadcast(MakananSegar.PubSub, "products", {:product_created, product})

      {:updated, product} ->
        Phoenix.PubSub.broadcast(MakananSegar.PubSub, "products", {:product_updated, product})

      {:deleted, product} ->
        Phoenix.PubSub.broadcast(MakananSegar.PubSub, "products", {:product_deleted, product.id})
    end
  end

  @doc """
  Returns the list of products.

  ## Examples

      iex> list_products(scope)
      [%Product{}, ...]

  """
  def list_products(%Scope{} = scope) do
    Repo.all_by(Product, user_id: scope.user.id)
  end

  @doc """
  Gets a single product.

  Raises `Ecto.NoResultsError` if the Product does not exist.

  ## Examples

      iex> get_product!(123)
      %Product{}

      iex> get_product!(456)
      ** (Ecto.NoResultsError)

  """
  def get_product!(%Scope{} = scope, id) do
    Repo.get_by!(Product, id: id, user_id: scope.user.id)
  end

  @doc """
  Creates a product.

  ## Examples

      iex> create_product(%{field: value})
      {:ok, %Product{}}

      iex> create_product(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_product(%Scope{} = scope, attrs) do
    with {:ok, product = %Product{}} <-
           %Product{}
           |> Product.changeset(attrs, scope)
           |> Repo.insert() do
      # Schedule automatic deletion when product expires
      ProductExpiryWorker.schedule_product_expiry(product.id, product.expires_at)

      broadcast(scope, {:created, product})
      {:ok, product}
    end
  end

  @doc """
  Updates a product.

  ## Examples

      iex> update_product(product, %{field: new_value})
      {:ok, %Product{}}

      iex> update_product(product, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_product(%Scope{} = scope, %Product{} = product, attrs) do
    if product.user_id == scope.user.id do
      with {:ok, updated_product = %Product{}} <-
             product
             |> Product.update_changeset(attrs)
             |> Repo.update() do
        # If expiry date changed, reschedule the expiry job
        if updated_product.expires_at != product.expires_at do
          ProductExpiryWorker.schedule_product_expiry(
            updated_product.id,
            updated_product.expires_at
          )
        end

        broadcast(scope, {:updated, updated_product})
        {:ok, updated_product}
      end
    else
      {:error, :unauthorized}
    end
  end

  @doc """
  Deletes a product.

  ## Examples

      iex> delete_product(product)
      {:ok, %Product{}}

      iex> delete_product(product)
      {:error, %Ecto.Changeset{}}

  """
  def delete_product(%Scope{} = scope, %Product{} = product) do
    if product.user_id == scope.user.id do
      with {:ok, product = %Product{}} <-
             Repo.delete(product) do
        broadcast(scope, {:deleted, product})
        {:ok, product}
      end
    else
      {:error, :unauthorized}
    end
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking product changes.

  ## Examples

      iex> change_product(product)
      %Ecto.Changeset{data: %Product{}}

  """
  def change_product(%Scope{} = scope, %Product{} = product, attrs \\ %{}) do
    if product.user_id == scope.user.id do
      Product.update_changeset(product, attrs)
    else
      Product.update_changeset(product, %{})
      |> Ecto.Changeset.add_error(:user_id, "unauthorized")
    end
  end

  @doc """
  Returns the list of all public products (for browsing).
  """
  def list_public_products do
    from(p in Product,
      where: p.is_active == true,
      order_by: [desc: p.inserted_at],
      preload: [:user]
    )
    |> Repo.all()
  end

  @doc """
  Returns the list of products by category.
  """
  def list_products_by_category(category) do
    from(p in Product,
      where: p.is_active == true and p.category == ^category,
      order_by: [desc: p.inserted_at],
      preload: [:user]
    )
    |> Repo.all()
  end

  @doc """
  Returns the list of expired products for a vendor.
  """
  def list_expired_products(%Scope{} = scope) do
    malaysia_now = DateTime.now!("Asia/Kuala_Lumpur")

    from(p in Product,
      where: p.user_id == ^scope.user.id and p.expires_at < ^malaysia_now,
      order_by: [desc: p.expires_at]
    )
    |> Repo.all()
  end

  @doc """
  Returns the list of products expiring soon for a vendor.
  """
  def list_expiring_soon_products(%Scope{} = scope) do
    malaysia_now = DateTime.now!("Asia/Kuala_Lumpur")
    twenty_four_hours_later = DateTime.add(malaysia_now, 24, :hour)

    from(p in Product,
      where:
        p.user_id == ^scope.user.id and
          p.expires_at > ^malaysia_now and
          p.expires_at <= ^twenty_four_hours_later,
      order_by: [asc: p.expires_at]
    )
    |> Repo.all()
  end

  @doc """
  Returns vendor statistics.
  """
  def get_vendor_stats(%Scope{} = scope) do
    products = list_products(scope)
    total_products = length(products)
    active_products = Enum.count(products, & &1.is_active)
    expired_products = Enum.count(products, &Product.expired?/1)
    expiring_soon = Enum.count(products, &Product.expiring_soon?/1)

    %{
      total_products: total_products,
      active_products: active_products,
      expired_products: expired_products,
      expiring_soon: expiring_soon
    }
  end

  @doc """
  Gets a public product by id (for public viewing).
  """
  def get_public_product!(id) do
    from(p in Product,
      where: p.id == ^id and p.is_active == true,
      preload: [:user]
    )
    |> Repo.one!()
  end

  @doc """
  Gets a product by ID if it belongs to the specified vendor.
  Returns nil if the product doesn't exist or doesn't belong to the vendor.
  """
  def get_product_by_vendor(product_id, vendor_user_id) do
    from(p in Product,
      where: p.id == ^product_id and p.user_id == ^vendor_user_id,
      preload: [:user]
    )
    |> Repo.one()
  end
end

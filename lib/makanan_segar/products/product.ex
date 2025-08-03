defmodule MakananSegar.Products.Product do
  use Ecto.Schema
  import Ecto.Changeset

  schema "products" do
    field :name, :string
    field :description, :string
    field :category, :string
    field :price, :decimal
    field :image, :string
    field :image_upload, :any, virtual: true
    field :expires_at, :utc_datetime
    field :is_active, :boolean, default: true

    belongs_to :user, MakananSegar.Accounts.User

    timestamps(type: :utc_datetime)
  end

  @categories ["fish", "vegetables", "fruits"]

  @doc false
  def changeset(product, attrs, user_scope \\ nil) do
    product
    |> cast(attrs, [
      :name,
      :description,
      :category,
      :price,
      :image,
      :image_upload,
      :expires_at,
      :is_active
    ])
    |> validate_required([:name, :description, :category, :price, :expires_at])
    |> validate_length(:name, min: 2, max: 100)
    |> validate_length(:description, min: 10, max: 1000)
    |> validate_inclusion(:category, @categories)
    |> validate_number(:price, greater_than: 0)
    |> validate_future_expiry()
    |> maybe_put_user_id(user_scope)
    |> validate_required([:user_id])
  end

  @doc """
  A changeset for updating product without requiring user scope
  """
  def update_changeset(product, attrs) do
    product
    |> cast(attrs, [
      :name,
      :description,
      :category,
      :price,
      :image,
      :image_upload,
      :expires_at,
      :is_active
    ])
    |> validate_required([:name, :description, :category, :price, :expires_at])
    |> validate_length(:name, min: 2, max: 100)
    |> validate_length(:description, min: 10, max: 1000)
    |> validate_inclusion(:category, @categories)
    |> validate_number(:price, greater_than: 0)
    |> validate_future_expiry()
  end

  defp validate_future_expiry(changeset) do
    expires_at = get_change(changeset, :expires_at)

    if expires_at do
      malaysia_now = DateTime.now!("Asia/Kuala_Lumpur")

      if DateTime.compare(expires_at, malaysia_now) == :lt do
        add_error(changeset, :expires_at, "must be in the future")
      else
        changeset
      end
    else
      changeset
    end
  end

  defp maybe_put_user_id(changeset, nil), do: changeset

  defp maybe_put_user_id(changeset, user_scope) do
    put_change(changeset, :user_id, user_scope.user.id)
  end

  @doc """
  Returns true if the product is expired
  """
  def expired?(%__MODULE__{expires_at: expires_at}) do
    malaysia_now = DateTime.now!("Asia/Kuala_Lumpur")
    DateTime.compare(expires_at, malaysia_now) == :lt
  end

  @doc """
  Returns true if the product is expiring soon (within 24 hours)
  """
  def expiring_soon?(%__MODULE__{expires_at: expires_at}) do
    malaysia_now = DateTime.now!("Asia/Kuala_Lumpur")
    twenty_four_hours_later = DateTime.add(malaysia_now, 24, :hour)

    DateTime.compare(expires_at, malaysia_now) == :gt &&
      DateTime.compare(expires_at, twenty_four_hours_later) == :lt
  end

  @doc """
  Returns the available categories
  """
  def categories, do: @categories

  @doc """
  Returns a human-readable category name
  """
  def category_display_name("fish"), do: "Fresh Fish"
  def category_display_name("vegetables"), do: "Fresh Vegetables"
  def category_display_name("fruits"), do: "Fresh Fruits"
  def category_display_name(category), do: String.capitalize(category)
end

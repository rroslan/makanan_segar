defmodule MakananSegar.ProductsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `MakananSegar.Products` context.
  """

  @doc """
  Generate a product.
  """
  def product_fixture(scope, attrs \\ %{}) do
    # Use a date 30 days in the future to ensure it's always valid
    future_date = DateTime.utc_now() |> DateTime.add(30, :day) |> DateTime.truncate(:second)

    attrs =
      Enum.into(attrs, %{
        category: "vegetables",
        description: "some description",
        expires_at: future_date,
        image: "some image",
        is_active: true,
        name: "some name",
        price: "120.5"
      })

    {:ok, product} = MakananSegar.Products.create_product(scope, attrs)
    product
  end
end

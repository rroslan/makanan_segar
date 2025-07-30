defmodule MakananSegar.ProductsTest do
  use MakananSegar.DataCase

  alias MakananSegar.Products

  describe "products" do
    alias MakananSegar.Products.Product

    import MakananSegar.AccountsFixtures, only: [user_scope_fixture: 0]
    import MakananSegar.ProductsFixtures

    @invalid_attrs %{
      name: nil,
      description: nil,
      image: nil,
      category: nil,
      price: nil,
      expires_at: nil,
      is_active: nil
    }

    test "list_products/1 returns all scoped products" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      product = product_fixture(scope)
      other_product = product_fixture(other_scope)

      # Compare products by ID since decimal precision might differ
      assert [returned_product] = Products.list_products(scope)
      assert returned_product.id == product.id

      assert [returned_other_product] = Products.list_products(other_scope)
      assert returned_other_product.id == other_product.id
    end

    test "get_product!/2 returns the product with given id" do
      scope = user_scope_fixture()
      product = product_fixture(scope)
      other_scope = user_scope_fixture()

      returned_product = Products.get_product!(scope, product.id)
      assert returned_product.id == product.id
      assert_raise Ecto.NoResultsError, fn -> Products.get_product!(other_scope, product.id) end
    end

    test "create_product/2 with valid data creates a product" do
      # Use a date 30 days in the future
      future_date = DateTime.utc_now() |> DateTime.add(30, :day) |> DateTime.truncate(:second)

      valid_attrs = %{
        name: "some name",
        description: "some description",
        image: "some image",
        # Use valid category
        category: "vegetables",
        price: "120.5",
        expires_at: future_date,
        is_active: true
      }

      scope = user_scope_fixture()

      assert {:ok, %Product{} = product} = Products.create_product(scope, valid_attrs)
      assert product.name == "some name"
      assert product.description == "some description"
      assert product.image == "some image"
      assert product.category == "vegetables"
      assert Decimal.equal?(product.price, Decimal.new("120.5"))
      assert DateTime.compare(product.expires_at, future_date) == :eq
      assert product.is_active == true
      assert product.user_id == scope.user.id
    end

    test "create_product/2 with invalid data returns error changeset" do
      scope = user_scope_fixture()
      assert {:error, %Ecto.Changeset{}} = Products.create_product(scope, @invalid_attrs)
    end

    test "update_product/3 with valid data updates the product" do
      scope = user_scope_fixture()
      product = product_fixture(scope)

      # Use a date 60 days in the future
      future_date = DateTime.utc_now() |> DateTime.add(60, :day) |> DateTime.truncate(:second)

      update_attrs = %{
        name: "some updated name",
        description: "some updated description",
        image: "some updated image",
        # Use valid category
        category: "fruits",
        price: "456.7",
        expires_at: future_date,
        is_active: false
      }

      assert {:ok, %Product{} = product} = Products.update_product(scope, product, update_attrs)
      assert product.name == "some updated name"
      assert product.description == "some updated description"
      assert product.image == "some updated image"
      assert product.category == "fruits"
      assert Decimal.equal?(product.price, Decimal.new("456.7"))
      assert DateTime.compare(product.expires_at, future_date) == :eq
      assert product.is_active == false
    end

    test "update_product/3 with invalid scope returns error" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      product = product_fixture(scope)

      # The function returns an error tuple instead of raising
      assert {:error, :unauthorized} = Products.update_product(other_scope, product, %{})
    end

    test "update_product/3 with invalid data returns error changeset" do
      scope = user_scope_fixture()
      product = product_fixture(scope)
      assert {:error, %Ecto.Changeset{}} = Products.update_product(scope, product, @invalid_attrs)

      # Verify product wasn't changed
      retrieved_product = Products.get_product!(scope, product.id)
      assert retrieved_product.id == product.id
      assert retrieved_product.name == product.name
    end

    test "delete_product/2 deletes the product" do
      scope = user_scope_fixture()
      product = product_fixture(scope)
      assert {:ok, %Product{}} = Products.delete_product(scope, product)
      assert_raise Ecto.NoResultsError, fn -> Products.get_product!(scope, product.id) end
    end

    test "delete_product/2 with invalid scope returns error" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      product = product_fixture(scope)

      # The function returns an error tuple instead of raising
      assert {:error, :unauthorized} = Products.delete_product(other_scope, product)
    end

    test "change_product/2 returns a product changeset" do
      scope = user_scope_fixture()
      product = product_fixture(scope)
      assert %Ecto.Changeset{} = Products.change_product(scope, product)
    end
  end
end

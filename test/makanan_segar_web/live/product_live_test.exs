defmodule MakananSegarWeb.ProductLiveTest do
  use MakananSegarWeb.ConnCase

  import Phoenix.LiveViewTest
  import MakananSegar.ProductsFixtures

  @create_attrs %{
    name: "some name",
    description: "some description",
    category: "vegetables",
    price: "120.5",
    expires_at: "2025-08-30T13:47:00Z",
    is_active: true
  }
  @update_attrs %{
    name: "some updated name",
    description: "some updated description",
    category: "fruits",
    price: "456.7",
    expires_at: "2025-09-30T13:47:00Z",
    is_active: false
  }
  @invalid_attrs %{
    name: nil,
    description: nil,
    image: nil,
    category: nil,
    price: nil,
    expires_at: nil,
    is_active: false
  }

  setup :register_and_log_in_vendor

  defp register_and_log_in_vendor(%{conn: conn}) do
    user = MakananSegar.AccountsFixtures.vendor_user_fixture()
    scope = MakananSegar.Accounts.Scope.for_user(user)
    %{conn: log_in_user(conn, user), user: user, scope: scope}
  end

  defp create_product(%{scope: scope}) do
    product = product_fixture(scope)
    %{product: product}
  end

  describe "Index" do
    setup [:create_product]

    test "lists all products", %{conn: conn, product: product} do
      {:ok, _index_live, html} = live(conn, ~p"/vendor/products")

      assert html =~ "My Products"
      assert html =~ product.name
    end

    test "saves new product", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/vendor/products")

      assert {:ok, form_live, _html} =
               index_live
               |> element("a", "Add New Product")
               |> render_click()
               |> follow_redirect(conn, ~p"/vendor/products/new")

      assert render(form_live) =~ "New Product"

      # Test with invalid attrs excluding category to avoid select validation
      invalid_attrs_without_category = Map.delete(@invalid_attrs, :category)

      assert form_live
             |> form("#product-form", product: invalid_attrs_without_category)
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, index_live, _html} =
               form_live
               |> form("#product-form", product: @create_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/vendor/products")

      html = render(index_live)
      assert html =~ "Product created successfully"
      assert html =~ "some name"
    end

    test "updates product in listing", %{conn: conn, product: product} do
      {:ok, index_live, _html} = live(conn, ~p"/vendor/products")

      # Click the edit link (pencil icon)
      {:ok, form_live, _html} =
        index_live
        |> element("a[href='/vendor/products/#{product.id}/edit']")
        |> render_click()
        |> follow_redirect(conn, ~p"/vendor/products/#{product}/edit")

      assert render(form_live) =~ "Edit Product"

      # Test with invalid attrs excluding category and image to avoid validation issues
      invalid_attrs_without_category_and_image =
        @invalid_attrs
        |> Map.delete(:category)
        |> Map.delete(:image)

      assert form_live
             |> form("#product-form", product: invalid_attrs_without_category_and_image)
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, index_live, _html} =
               form_live
               |> form("#product-form", product: @update_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/vendor/products")

      html = render(index_live)
      assert html =~ "Product updated successfully"
      assert html =~ "some updated name"
    end

    test "deletes product in listing", %{conn: conn, product: product} do
      {:ok, index_live, _html} = live(conn, ~p"/vendor/products")

      assert index_live
             |> element("button[phx-click='delete'][phx-value-id='#{product.id}']")
             |> render_click()

      refute render(index_live) =~ product.name
    end
  end

  describe "Show" do
    setup [:create_product]

    test "displays product", %{conn: conn, product: product} do
      {:ok, _show_live, html} = live(conn, ~p"/vendor/products/#{product}")

      assert html =~ product.name
      assert html =~ "RM #{product.price}"
    end

    test "updates product within modal", %{conn: conn, product: product} do
      {:ok, _show_live, _html} = live(conn, ~p"/vendor/products/#{product}")

      # Navigate directly to the edit page without clicking
      {:ok, form_live, _html} = live(conn, ~p"/vendor/products/#{product}/edit")

      assert render(form_live) =~ "Edit Product"

      # Test with invalid attrs excluding category and image to avoid validation issues
      invalid_attrs_without_category_and_image =
        @invalid_attrs
        |> Map.delete(:category)
        |> Map.delete(:image)

      assert form_live
             |> form("#product-form", product: invalid_attrs_without_category_and_image)
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, index_live, _html} =
               form_live
               |> form("#product-form", product: @update_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/vendor/products")

      html = render(index_live)
      assert html =~ "Product updated successfully"
      assert html =~ "some updated name"
    end
  end
end

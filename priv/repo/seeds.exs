# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     MakananSegar.Repo.insert!(%MakananSegar.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

alias MakananSegar.Repo
alias MakananSegar.Accounts
alias MakananSegar.Accounts.User
alias MakananSegar.Products
alias MakananSegar.Products.Product

# Clean database before seeding
IO.puts("🧹 Cleaning existing data...")
Repo.delete_all(Product)
Repo.delete_all(User)

# Specific user emails
admin_email = "rroslan@gmail.com"
fish_vendor_email = "roslanr@gmail.com"
vegetable_vendor_email = "rosslann.ramli@gmail.com"
fruit_vendor_email = "dev.rroslan@gmail.com"

IO.puts("🌱 Seeding minimal database for development...")
IO.puts("📧 Admin email: #{admin_email}")
IO.puts("📧 Fish vendor email: #{fish_vendor_email}")
IO.puts("📧 Vegetables vendor email: #{vegetable_vendor_email}")
IO.puts("📧 Fruits vendor email: #{fruit_vendor_email}")

# Helper function to create user with confirmation
create_user = fn email, attrs ->
  user_attrs =
    Map.merge(attrs, %{
      email: email
    })

  user =
    %User{}
    |> User.registration_changeset(user_attrs)
    |> Repo.insert!()
    |> User.confirm_changeset()
    |> Repo.update!()

  # Update admin and vendor flags using role changeset
  if Map.has_key?(attrs, :is_admin) or Map.has_key?(attrs, :is_vendor) do
    user
    |> User.role_changeset(attrs)
    |> Repo.update!()
  else
    user
  end
end

# Create Admin User
admin_user =
  create_user.(admin_email, %{
    name: "Roslan Ramli",
    is_admin: true,
    is_vendor: false
  })

IO.puts("✅ Created admin: #{admin_user.email}")

# Create Fish Vendor
fish_vendor =
  create_user.(fish_vendor_email, %{
    name: "Ahmad Fish Vendor",
    is_admin: false,
    is_vendor: true,
    business_name: "Ahmad's Fresh Fish Market",
    business_type: "fish"
  })

IO.puts("✅ Created fish vendor: #{fish_vendor.email}")

# Create Vegetable Vendor
vegetable_vendor =
  create_user.(vegetable_vendor_email, %{
    name: "Siti Vegetable Vendor",
    is_admin: false,
    is_vendor: true,
    business_name: "Siti's Organic Vegetables",
    business_type: "vegetables"
  })

IO.puts("✅ Created vegetable vendor: #{vegetable_vendor.email}")

# Create Fruit Vendor
fruit_vendor =
  create_user.(fruit_vendor_email, %{
    name: "Lim Fruit Vendor",
    is_admin: false,
    is_vendor: true,
    business_name: "Lim's Tropical Fruits",
    business_type: "fruits"
  })

IO.puts("✅ Created fruit vendor: #{fruit_vendor.email}")

# Create 2 products per vendor
IO.puts("\n🛒 Creating 2 products per vendor...")

# Fish vendor products
fish_products = [
  %{
    name: "Fresh Red Snapper",
    description:
      "Wild-caught red snapper from Terengganu waters. Perfect for steaming or grilling.",
    price: Decimal.new("28.90"),
    category: "fish",
    expires_at: DateTime.add(DateTime.utc_now(), 2, :day),
    is_active: true,
    user_id: fish_vendor.id
  },
  %{
    name: "Tiger Prawns",
    description: "Fresh large tiger prawns. Already cleaned and deveined.",
    price: Decimal.new("45.00"),
    category: "fish",
    expires_at: DateTime.add(DateTime.utc_now(), 1, :day),
    is_active: true,
    user_id: fish_vendor.id
  }
]

# Vegetable vendor products
vegetable_products = [
  %{
    name: "Organic Baby Spinach",
    description: "Fresh organic baby spinach from Cameron Highlands. Pesticide-free.",
    price: Decimal.new("6.50"),
    category: "vegetables",
    expires_at: DateTime.add(DateTime.utc_now(), 5, :day),
    is_active: true,
    user_id: vegetable_vendor.id
  },
  %{
    name: "Cherry Tomatoes",
    description: "Sweet cherry tomatoes, perfect for salads. Grown using sustainable methods.",
    price: Decimal.new("9.90"),
    category: "vegetables",
    expires_at: DateTime.add(DateTime.utc_now(), 7, :day),
    is_active: true,
    user_id: vegetable_vendor.id
  }
]

# Fruit vendor products
fruit_products = [
  %{
    name: "Musang King Durian",
    description: "Premium Musang King durian from Pahang. Creamy, sweet, and aromatic.",
    price: Decimal.new("95.00"),
    category: "fruits",
    expires_at: DateTime.add(DateTime.utc_now(), 3, :day),
    is_active: true,
    user_id: fruit_vendor.id
  },
  %{
    name: "Dragon Fruit",
    description: "Sweet red dragon fruit with vibrant color. Rich in antioxidants.",
    price: Decimal.new("14.90"),
    category: "fruits",
    expires_at: DateTime.add(DateTime.utc_now(), 6, :day),
    is_active: true,
    user_id: fruit_vendor.id
  }
]

# Insert all products
all_products = fish_products ++ vegetable_products ++ fruit_products

Enum.each(all_products, fn product_attrs ->
  changeset =
    %Product{}
    |> Product.update_changeset(product_attrs)
    |> Ecto.Changeset.put_change(:user_id, product_attrs.user_id)

  case Repo.insert(changeset) do
    {:ok, product} ->
      IO.puts("✅ Created: #{product.name} - RM#{product.price} (#{product.category})")

    {:error, changeset} ->
      IO.puts("❌ Failed to create product: #{inspect(changeset.errors)}")
  end
end)

IO.puts("\n" <> String.duplicate("=", 50))
IO.puts("🎉 SEEDING COMPLETED")
IO.puts(String.duplicate("=", 50))
IO.puts("👤 Admin:           #{admin_email}")
IO.puts("🐟 Fish Vendor:     #{fish_vendor_email}")
IO.puts("🥬 Vegetable Vendor: #{vegetable_vendor_email}")
IO.puts("🍎 Fruit Vendor:    #{fruit_vendor_email}")
IO.puts(String.duplicate("-", 50))
IO.puts("👤 Users: #{Repo.aggregate(User, :count, :id)}")
IO.puts("🛒 Products: #{Repo.aggregate(Product, :count, :id)}")
IO.puts("\n✨ Ready for manual development!")

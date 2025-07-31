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

# Get environment variables for seeding
admin_email = System.get_env("ADMIN_EMAIL", "rroslan@gmail.com")
fish_vendor_email = System.get_env("FISH_VENDOR_EMAIL", "roslanr@gmail.com")
vegetables_vendor_email = System.get_env("VEGETABLES_VENDOR_EMAIL", "rosslann.ramli@gmail.com")
fruits_vendor_email = System.get_env("FRUITS_VENDOR_EMAIL", "fruits.vendor@example.com")

# Helper function to create or update user
create_or_update_user = fn email, attrs ->
  case Accounts.get_user_by_email(email) do
    nil ->
      %User{}
      |> User.registration_changeset(attrs)
      |> Repo.insert!()
      |> then(fn user ->
        # Confirm the user immediately for seeded users
        user
        |> User.confirm_changeset()
        |> Repo.update!()
      end)

    user ->
      user
      |> User.role_changeset(attrs)
      |> Repo.update!()
  end
end

IO.puts("🌱 Seeding database with initial users...")

# Create Admin User
admin_user =
  create_or_update_user.(admin_email, %{
    name: "Admin User",
    email: admin_email,
    is_admin: true,
    is_vendor: false,
    address: "Admin Office, Kuala Lumpur, Malaysia"
  })

# Update admin role
admin_user =
  admin_user
  |> User.role_changeset(%{is_admin: true, is_vendor: false})
  |> Repo.update!()

IO.puts("✅ Created admin user: #{admin_user.email}")

# Create Fish Vendor
fish_vendor =
  create_or_update_user.(fish_vendor_email, %{
    name: "Fresh Fish Vendor",
    email: fish_vendor_email,
    is_admin: false,
    is_vendor: false,
    address: "Pasar Borong Selayang, Selangor, Malaysia"
  })

# Update vendor role and business info
fish_vendor =
  fish_vendor
  |> User.role_changeset(%{is_admin: false, is_vendor: true})
  |> Repo.update!()

# Update business information
fish_vendor =
  fish_vendor
  |> User.profile_changeset(%{
    business_name: "Pasar Ikan Segar",
    business_description: "Fresh fish from local waters, caught daily",
    business_type: "fish",
    phone: "+60123456789",
    business_hours: "6:00 AM - 2:00 PM daily",
    website: "https://pasarikansegar.com"
  })
  |> Repo.update!()

IO.puts("✅ Created fish vendor: #{fish_vendor.email}")

# Create Vegetables Vendor
vegetables_vendor =
  create_or_update_user.(vegetables_vendor_email, %{
    name: "Fresh Vegetables Vendor",
    email: vegetables_vendor_email,
    is_admin: false,
    is_vendor: false,
    address: "9 Taman Chendor Perdana 1/15, Kuantan 26080, Malaysia"
  })

# Update vendor role and business info
vegetables_vendor =
  vegetables_vendor
  |> User.role_changeset(%{is_admin: false, is_vendor: true})
  |> Repo.update!()

# Update business information
vegetables_vendor =
  vegetables_vendor
  |> User.profile_changeset(%{
    business_name: "Sayur Organik Kuantan",
    business_description: "Organic vegetables grown locally in Pahang",
    business_type: "vegetables",
    phone: "+60129876543",
    business_hours: "7:00 AM - 6:00 PM daily",
    website: "https://sayurorganikkuantan.com"
  })
  |> Repo.update!()

IO.puts("✅ Created vegetables vendor: #{vegetables_vendor.email}")

# Create Fruits Vendor
fruits_vendor =
  create_or_update_user.(fruits_vendor_email, %{
    name: "Fresh Fruits Vendor",
    email: fruits_vendor_email,
    is_admin: false,
    is_vendor: false,
    address: "Pasar Malam Taman Connaught, Cheras, Kuala Lumpur, Malaysia"
  })

# Update vendor role and business info
fruits_vendor =
  fruits_vendor
  |> User.role_changeset(%{is_admin: false, is_vendor: true})
  |> Repo.update!()

# Update business information
fruits_vendor =
  fruits_vendor
  |> User.profile_changeset(%{
    business_name: "Buah-buahan Tropika",
    business_description: "Tropical fruits from Cameron Highlands and local farms",
    business_type: "fruits",
    phone: "+60111122334",
    business_hours: "8:00 AM - 8:00 PM daily",
    website: "https://buahtropika.com"
  })
  |> Repo.update!()

IO.puts("✅ Created fruits vendor: #{fruits_vendor.email}")

# Create additional vendor for testing
seafood_vendor =
  create_or_update_user.("seafood.vendor@example.com", %{
    name: "Premium Seafood Vendor",
    email: "seafood.vendor@example.com",
    is_admin: false,
    is_vendor: false,
    address: "Klang Seafood Market, Selangor, Malaysia"
  })

seafood_vendor =
  seafood_vendor
  |> User.role_changeset(%{is_admin: false, is_vendor: true})
  |> Repo.update!()

# Update business information
seafood_vendor =
  seafood_vendor
  |> User.profile_changeset(%{
    business_name: "Premium Seafood Enterprise",
    business_description: "High-quality seafood and marine products",
    business_type: "fish",
    phone: "+60145556666",
    business_hours: "5:00 AM - 1:00 PM daily"
  })
  |> Repo.update!()

IO.puts("✅ Created seafood vendor: #{seafood_vendor.email}")

# Reload vendors to get fresh IDs for product creation
fish_vendor = Repo.get_by!(User, email: fish_vendor_email)
vegetables_vendor = Repo.get_by!(User, email: vegetables_vendor_email)
fruits_vendor = Repo.get_by!(User, email: fruits_vendor_email)
seafood_vendor = Repo.get_by!(User, email: "seafood.vendor@example.com")

# Create some sample regular users
sample_users = [
  %{
    name: "John Customer",
    email: "john.customer@example.com",
    is_admin: false,
    is_vendor: false,
    address: "Petaling Jaya, Selangor, Malaysia",
    phone: "+60123456789"
  },
  %{
    name: "Sarah Buyer",
    email: "sarah.buyer@example.com",
    is_admin: false,
    is_vendor: false,
    address: "Shah Alam, Selangor, Malaysia",
    phone: "+60129876543"
  },
  %{
    name: "Ahmad Rahman",
    email: "ahmad.rahman@example.com",
    is_admin: false,
    is_vendor: false,
    address: "Ampang, Kuala Lumpur, Malaysia",
    phone: "+60111122334"
  },
  %{
    name: "Lim Wei Ming",
    email: "lim.weiming@example.com",
    is_admin: false,
    is_vendor: false,
    address: "Johor Bahru, Johor, Malaysia",
    phone: "+60177788899"
  }
]

Enum.each(sample_users, fn user_attrs ->
  user = create_or_update_user.(user_attrs.email, user_attrs)
  IO.puts("✅ Created sample user: #{user.email}")
end)

# Create sample products for vendors
IO.puts("\n🛒 Creating sample products...")

# Fish products
fish_products = [
  %{
    name: "Fresh Red Snapper",
    description: "Wild-caught red snapper, perfect for grilling or steaming",
    price: Decimal.new("25.90"),
    category: "fish",
    expires_at: DateTime.add(DateTime.utc_now(), 2, :day),
    is_active: true,
    user_id: fish_vendor.id
  },
  %{
    name: "Premium Salmon Fillet",
    description: "Norwegian salmon fillet, rich in omega-3",
    price: Decimal.new("45.00"),
    category: "fish",
    expires_at: DateTime.add(DateTime.utc_now(), 3, :day),
    is_active: true,
    user_id: fish_vendor.id
  },
  %{
    name: "Fresh Prawns (Medium)",
    description: "Local prawns, cleaned and deveined",
    price: Decimal.new("35.50"),
    category: "fish",
    expires_at: DateTime.add(DateTime.utc_now(), 1, :day),
    is_active: true,
    user_id: fish_vendor.id
  }
]

# Vegetables products
vegetables_products = [
  %{
    name: "Organic Spinach",
    description: "Fresh organic spinach, pesticide-free",
    price: Decimal.new("5.50"),
    category: "vegetables",
    expires_at: DateTime.add(DateTime.utc_now(), 5, :day),
    is_active: true,
    user_id: vegetables_vendor.id
  },
  %{
    name: "Cherry Tomatoes",
    description: "Sweet cherry tomatoes, perfect for salads",
    price: Decimal.new("8.90"),
    category: "vegetables",
    expires_at: DateTime.add(DateTime.utc_now(), 7, :day),
    is_active: true,
    user_id: vegetables_vendor.id
  },
  %{
    name: "Baby Carrots",
    description: "Tender baby carrots, great for snacking",
    price: Decimal.new("6.50"),
    category: "vegetables",
    expires_at: DateTime.add(DateTime.utc_now(), 10, :day),
    is_active: true,
    user_id: vegetables_vendor.id
  },
  %{
    name: "Organic Lettuce",
    description: "Crisp organic lettuce leaves",
    price: Decimal.new("4.90"),
    category: "vegetables",
    expires_at: DateTime.add(DateTime.utc_now(), 4, :day),
    is_active: true,
    user_id: vegetables_vendor.id
  }
]

# Fruits products
fruits_products = [
  %{
    name: "Dragon Fruit",
    description: "Sweet and refreshing dragon fruit",
    price: Decimal.new("12.90"),
    category: "fruits",
    expires_at: DateTime.add(DateTime.utc_now(), 6, :day),
    is_active: true,
    user_id: fruits_vendor.id
  },
  %{
    name: "Cameron Highland Strawberries",
    description: "Fresh strawberries from Cameron Highlands",
    price: Decimal.new("15.50"),
    category: "fruits",
    expires_at: DateTime.add(DateTime.utc_now(), 4, :day),
    is_active: true,
    user_id: fruits_vendor.id
  },
  %{
    name: "Local Durian (Musang King)",
    description: "Premium Musang King durian, creamy and sweet",
    price: Decimal.new("85.00"),
    category: "fruits",
    expires_at: DateTime.add(DateTime.utc_now(), 3, :day),
    is_active: true,
    user_id: fruits_vendor.id
  },
  %{
    name: "Tropical Mango",
    description: "Sweet and juicy tropical mangoes",
    price: Decimal.new("8.90"),
    category: "fruits",
    expires_at: DateTime.add(DateTime.utc_now(), 5, :day),
    is_active: true,
    user_id: fruits_vendor.id
  }
]

# Seafood products
seafood_products = [
  %{
    name: "Live Mud Crabs",
    description: "Fresh live mud crabs from Klang",
    price: Decimal.new("65.00"),
    category: "fish",
    expires_at: DateTime.add(DateTime.utc_now(), 1, :day),
    is_active: true,
    user_id: seafood_vendor.id
  },
  %{
    name: "Sea Bass Fillet",
    description: "Premium sea bass fillet, boneless",
    price: Decimal.new("28.90"),
    category: "fish",
    expires_at: DateTime.add(DateTime.utc_now(), 2, :day),
    is_active: true,
    user_id: seafood_vendor.id
  }
]

# Insert all products
all_products = fish_products ++ vegetables_products ++ fruits_products ++ seafood_products

Enum.each(all_products, fn product_attrs ->
  changeset =
    %Product{}
    |> Product.update_changeset(product_attrs)
    |> Ecto.Changeset.put_change(:user_id, product_attrs.user_id)
    |> Ecto.Changeset.validate_required([:user_id])

  case Repo.insert(changeset) do
    {:ok, product} ->
      IO.puts("✅ Created product: #{product.name} (#{product.category})")

    {:error, changeset} ->
      IO.puts("❌ Failed to create product: #{inspect(changeset.errors)}")
  end
end)

IO.puts("\n🎉 Database seeding completed!")
IO.puts("\n📧 Login credentials for testing:")
IO.puts("   Admin: #{admin_email}")
IO.puts("   Fish Vendor: #{fish_vendor_email}")
IO.puts("   Vegetables Vendor: #{vegetables_vendor_email}")
IO.puts("   Fruits Vendor: #{fruits_vendor_email}")
IO.puts("   Seafood Vendor: seafood.vendor@example.com")

IO.puts("\n👥 Sample customers:")

Enum.each(sample_users, fn user ->
  IO.puts("   #{user.email}")
end)

IO.puts("\n🚀 You can now start the application with: mix phx.server")
IO.puts("📬 Magic link emails can be viewed at: http://localhost:4000/dev/mailbox")

IO.puts(
  "\n💡 The vegetables vendor address has been set to: '9 Taman Chendor Perdana 1/15, Kuantan 26080, Malaysia'"
)

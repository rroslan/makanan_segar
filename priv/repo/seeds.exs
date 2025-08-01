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

# Helper function to get current Malaysian time (UTC+8)
malaysian_now = fn ->
  DateTime.now!("Asia/Kuala_Lumpur")
end

# Helper function to add days to Malaysian time
add_days_to_malaysian_time = fn days ->
  malaysian_now.()
  |> DateTime.add(days, :day)
end

# Clean database before seeding
IO.puts("🧹 Cleaning existing data...")
Repo.delete_all(Product)
Repo.delete_all(User)

# Use environment variables for VPS deployment, fallback to defaults for local development
admin_email = System.get_env("ADMIN_EMAIL") || "rroslan@gmail.com"
fish_vendor_email = System.get_env("FISH_VENDOR_EMAIL") || "roslanr@gmail.com"
vegetable_vendor_email = System.get_env("VEGETABLES_VENDOR_EMAIL") || "rosslann.ramli@gmail.com"
fruit_vendor_email = System.get_env("FRUITS_VENDOR_EMAIL") || "dev.rroslan@gmail.com"

# Show environment context
env_context = if System.get_env("MIX_ENV") == "prod", do: "PRODUCTION", else: "DEVELOPMENT"
current_malaysian_time = malaysian_now.()
IO.puts("🌱 Seeding comprehensive database for #{env_context}...")
IO.puts("🕐 Malaysian time: #{DateTime.to_string(current_malaysian_time)} (UTC+8)")
IO.puts("📧 Admin email: #{admin_email}")
IO.puts("📧 Fish vendor email: #{fish_vendor_email}")
IO.puts("📧 Vegetables vendor email: #{vegetable_vendor_email}")
IO.puts("📧 Fruits vendor email: #{fruit_vendor_email}")

# Log if using environment variables or defaults
env_source = if System.get_env("ADMIN_EMAIL"), do: "environment variables", else: "default values"
IO.puts("📝 Using #{env_source} for email addresses")

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
    is_vendor: false,
    phone: "+60123456789",
    address: "Kuala Lumpur, Malaysia"
  })

IO.puts("✅ Created admin: #{admin_user.email}")

# Create Fish Vendor
fish_vendor =
  create_user.(fish_vendor_email, %{
    name: "Ahmad Fish Vendor",
    is_admin: false,
    is_vendor: true,
    business_name: "Ahmad's Fresh Fish Market",
    business_type: "fish",
    phone: "+60198765432",
    address: "Pasar Borong Selayang, Selangor"
  })

IO.puts("✅ Created fish vendor: #{fish_vendor.email}")

# Create Vegetable Vendor
vegetable_vendor =
  create_user.(vegetable_vendor_email, %{
    name: "Siti Vegetable Vendor",
    is_admin: false,
    is_vendor: true,
    business_name: "Siti's Organic Vegetables",
    business_type: "vegetables",
    phone: "+60187654321",
    address: "Cameron Highlands, Pahang"
  })

IO.puts("✅ Created vegetable vendor: #{vegetable_vendor.email}")

# Create Fruit Vendor
fruit_vendor =
  create_user.(fruit_vendor_email, %{
    name: "Lim Fruit Vendor",
    is_admin: false,
    is_vendor: true,
    business_name: "Lim's Tropical Fruits",
    business_type: "fruits",
    phone: "+60176543210",
    address: "Pasar Malam Taman Connaught, Cheras, KL"
  })

IO.puts("✅ Created fruit vendor: #{fruit_vendor.email}")

# Create Sample Customers
_customer1 =
  create_user.("customer1@example.com", %{
    name: "John Customer",
    is_admin: false,
    is_vendor: false,
    phone: "+60123111111",
    address: "Petaling Jaya, Selangor"
  })

_customer2 =
  create_user.("customer2@example.com", %{
    name: "Sarah Buyer",
    is_admin: false,
    is_vendor: false,
    phone: "+60123222222",
    address: "Mont Kiara, Kuala Lumpur"
  })

_customer3 =
  create_user.("customer3@example.com", %{
    name: "Ahmad Customer",
    is_admin: false,
    is_vendor: false,
    phone: "+60123333333",
    address: "Subang Jaya, Selangor"
  })

IO.puts("✅ Created 3 sample customers")

# Create comprehensive product listings
IO.puts("\n🛒 Creating comprehensive product catalog...")

# Fish vendor products (5 products)
fish_products = [
  %{
    name: "Fresh Red Snapper",
    description:
      "Wild-caught red snapper from Terengganu waters. Perfect for steaming or grilling. Best served with ginger and soy sauce.",
    price: Decimal.new("28.90"),
    category: "fish",
    expires_at: add_days_to_malaysian_time.(2),
    is_active: true,
    user_id: fish_vendor.id
  },
  %{
    name: "Tiger Prawns",
    description:
      "Fresh large tiger prawns. Already cleaned and deveined. Excellent for sambal prawns or butter prawns.",
    price: Decimal.new("45.00"),
    category: "fish",
    expires_at: add_days_to_malaysian_time.(1),
    is_active: true,
    user_id: fish_vendor.id
  },
  %{
    name: "Sea Bass Fillet",
    description:
      "Premium sea bass fillet, boneless and skinless. Perfect for pan-frying or steaming with black bean sauce.",
    price: Decimal.new("38.50"),
    category: "fish",
    expires_at: add_days_to_malaysian_time.(2),
    is_active: true,
    user_id: fish_vendor.id
  },
  %{
    name: "Fresh Mackerel",
    description:
      "Local mackerel from Pantai Timur. Great for grilling or making gulai ikan. Rich in omega-3.",
    price: Decimal.new("18.90"),
    category: "fish",
    expires_at: add_days_to_malaysian_time.(1),
    is_active: true,
    user_id: fish_vendor.id
  },
  %{
    name: "Mud Crabs",
    description:
      "Live mud crabs from mangrove farms. Perfect for chili crab or salted egg crab. Size: 500g+",
    price: Decimal.new("65.00"),
    category: "fish",
    expires_at: add_days_to_malaysian_time.(3),
    is_active: true,
    user_id: fish_vendor.id
  }
]

# Vegetable vendor products (6 products)
vegetable_products = [
  %{
    name: "Organic Baby Spinach",
    description:
      "Fresh organic baby spinach from Cameron Highlands. Pesticide-free and perfect for salads or stir-frying.",
    price: Decimal.new("6.50"),
    category: "vegetables",
    expires_at: add_days_to_malaysian_time.(5),
    is_active: true,
    user_id: vegetable_vendor.id
  },
  %{
    name: "Cherry Tomatoes",
    description:
      "Sweet cherry tomatoes, perfect for salads. Grown using sustainable methods. Great for pasta dishes too.",
    price: Decimal.new("9.90"),
    category: "vegetables",
    expires_at: add_days_to_malaysian_time.(7),
    is_active: true,
    user_id: vegetable_vendor.id
  },
  %{
    name: "Japanese Cucumber",
    description:
      "Crisp Japanese cucumbers with thin skin. No need to peel. Perfect for sushi rolls or fresh salads.",
    price: Decimal.new("5.50"),
    category: "vegetables",
    expires_at: add_days_to_malaysian_time.(6),
    is_active: true,
    user_id: vegetable_vendor.id
  },
  %{
    name: "Rainbow Carrots",
    description:
      "Colorful heirloom carrots in purple, orange, and yellow. Sweet and crunchy. Great for roasting.",
    price: Decimal.new("12.90"),
    category: "vegetables",
    expires_at: add_days_to_malaysian_time.(10),
    is_active: true,
    user_id: vegetable_vendor.id
  },
  %{
    name: "Organic Kale",
    description:
      "Nutrient-dense organic kale leaves. Perfect for smoothies, salads, or as a healthy side dish.",
    price: Decimal.new("8.50"),
    category: "vegetables",
    expires_at: add_days_to_malaysian_time.(4),
    is_active: true,
    user_id: vegetable_vendor.id
  },
  %{
    name: "Bell Peppers Mix",
    description:
      "Mixed bell peppers in red, yellow, and green. Sweet and crunchy. Great for stir-fries and stuffing.",
    price: Decimal.new("15.90"),
    category: "vegetables",
    expires_at: add_days_to_malaysian_time.(8),
    is_active: true,
    user_id: vegetable_vendor.id
  }
]

# Fruit vendor products (6 products)
fruit_products = [
  %{
    name: "Musang King Durian",
    description:
      "Premium Musang King durian from Pahang. Creamy, sweet, and aromatic. The king of fruits at its finest.",
    price: Decimal.new("95.00"),
    category: "fruits",
    expires_at: add_days_to_malaysian_time.(3),
    is_active: true,
    user_id: fruit_vendor.id
  },
  %{
    name: "Dragon Fruit",
    description:
      "Sweet red dragon fruit with vibrant color. Rich in antioxidants and perfect for fruit salads.",
    price: Decimal.new("14.90"),
    category: "fruits",
    expires_at: add_days_to_malaysian_time.(6),
    is_active: true,
    user_id: fruit_vendor.id
  },
  %{
    name: "Cameron Strawberries",
    description:
      "Fresh strawberries from Cameron Highlands. Sweet and juicy. Perfect for desserts or eating fresh.",
    price: Decimal.new("18.50"),
    category: "fruits",
    expires_at: add_days_to_malaysian_time.(3),
    is_active: true,
    user_id: fruit_vendor.id
  },
  %{
    name: "Harumanis Mango",
    description:
      "Premium Harumanis mango from Perlis. Incredibly sweet and fragrant. Limited season availability.",
    price: Decimal.new("25.00"),
    category: "fruits",
    expires_at: add_days_to_malaysian_time.(4),
    is_active: true,
    user_id: fruit_vendor.id
  },
  %{
    name: "Fresh Rambutan",
    description:
      "Sweet and juicy rambutan from local orchards. Peeled and ready to eat. A tropical delicacy.",
    price: Decimal.new("12.90"),
    category: "fruits",
    expires_at: add_days_to_malaysian_time.(2),
    is_active: true,
    user_id: fruit_vendor.id
  },
  %{
    name: "Passion Fruit",
    description:
      "Aromatic passion fruit with intense flavor. Perfect for juices, desserts, or eating fresh.",
    price: Decimal.new("16.50"),
    category: "fruits",
    expires_at: add_days_to_malaysian_time.(5),
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

IO.puts("✅ Skipping chat conversations for cleaner seeding")

IO.puts("\n" <> String.duplicate("=", 60))
IO.puts("🎉 COMPREHENSIVE SEEDING COMPLETED")
IO.puts(String.duplicate("=", 60))
IO.puts("👤 Admin:              #{admin_email}")
IO.puts("🐟 Fish Vendor:        #{fish_vendor_email}")
IO.puts("🥬 Vegetable Vendor:   #{vegetable_vendor_email}")
IO.puts("🍎 Fruit Vendor:       #{fruit_vendor_email}")
IO.puts(String.duplicate("-", 60))
IO.puts("👥 Users: #{Repo.aggregate(User, :count, :id)} (including 3 customers)")
IO.puts("🛒 Products: #{Repo.aggregate(Product, :count, :id)} (across 3 categories)")
IO.puts(String.duplicate("-", 60))
IO.puts("🔗 Authentication: Magic link (no passwords needed)")
IO.puts("")
IO.puts("🧪 Test Scenarios Available:")
IO.puts("   • Rich product catalog with Malaysian context")
IO.puts("   • Sample customers ready for testing")
IO.puts("   • Fresh food expiry dates in Malaysian time")
IO.puts("   • Realistic vendor profiles and business info")
IO.puts("")
IO.puts("✨ Ready for comprehensive development and testing!")

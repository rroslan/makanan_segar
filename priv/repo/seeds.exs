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
alias MakananSegar.Chat
alias MakananSegar.Chat.Message
alias MakananSegar.Chat.Conversation

# Clean database before seeding
IO.puts("🧹 Cleaning existing data...")
Repo.delete_all(Message)
Repo.delete_all(Conversation)
Repo.delete_all(Product)
Repo.delete_all(User)

# Get base email from environment or use default
base_email = System.get_env("SEED_EMAIL", "test@example.com")

# Extract the local part and domain
[local_part, domain] = String.split(base_email, "@", parts: 2)

# Create user emails based on the base email
admin_email = "#{local_part}+admin@#{domain}"
fish_vendor_email = "#{local_part}+fish@#{domain}"
vegetable_vendor_email = "#{local_part}+vegetables@#{domain}"
fruit_vendor_email = "#{local_part}+fruits@#{domain}"

IO.puts("🌱 Seeding database with test data...")
IO.puts("📧 Base email: #{base_email}")

# Helper function to create user with confirmation
create_user = fn email, attrs ->
  user_attrs = Map.merge(attrs, %{
    email: email,
    password: "password123",
    password_confirmation: "password123"
  })

  %User{}
  |> User.registration_changeset(user_attrs)
  |> Repo.insert!()
  |> User.confirm_changeset()
  |> Repo.update!()
end

# Create Admin User
admin_user = create_user.(admin_email, %{
  name: "Admin User",
  is_admin: true,
  is_vendor: false,
  address: "Admin Office, Kuala Lumpur, Malaysia",
  phone: "+60123456789"
})

IO.puts("✅ Created admin: #{admin_user.email}")

# Create Fish Vendor
fish_vendor = create_user.(fish_vendor_email, %{
  name: "Ahmad Fish Vendor",
  is_admin: false,
  is_vendor: true,
  address: "Pasar Borong Selayang, Selangor, Malaysia",
  phone: "+60123456001",
  business_name: "Ahmad's Fresh Fish Market",
  business_description: "Fresh fish from local waters, caught daily. Specializing in sea bass, red snapper, and prawns.",
  business_type: "fish",
  business_hours: "6:00 AM - 2:00 PM daily",
  website: "https://ahmadfish.com"
})

IO.puts("✅ Created fish vendor: #{fish_vendor.email}")

# Create Vegetable Vendor
vegetable_vendor = create_user.(vegetable_vendor_email, %{
  name: "Siti Vegetable Vendor",
  is_admin: false,
  is_vendor: true,
  address: "Cameron Highlands, Pahang, Malaysia",
  phone: "+60123456002",
  business_name: "Siti's Organic Vegetables",
  business_description: "Fresh organic vegetables grown in Cameron Highlands. Pesticide-free and sustainably farmed.",
  business_type: "vegetables",
  business_hours: "7:00 AM - 6:00 PM daily",
  website: "https://sitiorganic.com"
})

IO.puts("✅ Created vegetable vendor: #{vegetable_vendor.email}")

# Create Fruit Vendor
fruit_vendor = create_user.(fruit_vendor_email, %{
  name: "Lim Fruit Vendor",
  is_admin: false,
  is_vendor: true,
  address: "Pasar Malam Taman Connaught, Cheras, KL, Malaysia",
  phone: "+60123456003",
  business_name: "Lim's Tropical Fruits",
  business_description: "Premium tropical fruits from local farms. Specializing in durian, dragon fruit, and exotic fruits.",
  business_type: "fruits",
  business_hours: "8:00 AM - 8:00 PM daily",
  website: "https://limfruits.com"
})

IO.puts("✅ Created fruit vendor: #{fruit_vendor.email}")

# Create sample customers
customers = [
  create_user.("#{local_part}+customer1@#{domain}", %{
    name: "John Customer",
    is_admin: false,
    is_vendor: false,
    address: "Petaling Jaya, Selangor, Malaysia",
    phone: "+60123456100"
  }),

  create_user.("#{local_part}+customer2@#{domain}", %{
    name: "Sarah Buyer",
    is_admin: false,
    is_vendor: false,
    address: "Shah Alam, Selangor, Malaysia",
    phone: "+60123456101"
  }),

  create_user.("#{local_part}+customer3@#{domain}", %{
    name: "Ahmad Customer",
    is_admin: false,
    is_vendor: false,
    address: "Ampang, Kuala Lumpur, Malaysia",
    phone: "+60123456102"
  })
]

IO.puts("✅ Created #{length(customers)} customer accounts")

# Create products for each vendor
IO.puts("\n🛒 Creating sample products...")

# Fish vendor products
fish_products = [
  %{
    name: "Fresh Red Snapper",
    description: "Wild-caught red snapper from Terengganu waters. Perfect for steaming, grilling, or curry. Cleaned and scaled.",
    price: Decimal.new("28.90"),
    category: "fish",
    expires_at: DateTime.add(DateTime.utc_now(), 2, :day),
    is_active: true,
    user_id: fish_vendor.id
  },
  %{
    name: "Tiger Prawns (Large)",
    description: "Fresh large tiger prawns. Already cleaned and deveined. Perfect for BBQ or tom yam.",
    price: Decimal.new("45.00"),
    category: "fish",
    expires_at: DateTime.add(DateTime.utc_now(), 1, :day),
    is_active: true,
    user_id: fish_vendor.id
  },
  %{
    name: "Sea Bass Fillet",
    description: "Premium sea bass fillet, boneless and skin-on. Great for pan-frying or baking.",
    price: Decimal.new("35.50"),
    category: "fish",
    expires_at: DateTime.add(DateTime.utc_now(), 2, :day),
    is_active: true,
    user_id: fish_vendor.id
  },
  %{
    name: "Fresh Mackerel",
    description: "Local mackerel fish, rich in omega-3. Perfect for grilling with sambal.",
    price: Decimal.new("15.90"),
    category: "fish",
    expires_at: DateTime.add(DateTime.utc_now(), 1, :day),
    is_active: true,
    user_id: fish_vendor.id
  },
  %{
    name: "Live Mud Crabs",
    description: "Live mud crabs from Klang. Best enjoyed with chili or black pepper sauce.",
    price: Decimal.new("68.00"),
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
    description: "Fresh organic baby spinach from Cameron Highlands. Pesticide-free and tender leaves.",
    price: Decimal.new("6.50"),
    category: "vegetables",
    expires_at: DateTime.add(DateTime.utc_now(), 5, :day),
    is_active: true,
    user_id: vegetable_vendor.id
  },
  %{
    name: "Cherry Tomatoes",
    description: "Sweet cherry tomatoes, perfect for salads. Grown using sustainable farming methods.",
    price: Decimal.new("9.90"),
    category: "vegetables",
    expires_at: DateTime.add(DateTime.utc_now(), 7, :day),
    is_active: true,
    user_id: vegetable_vendor.id
  },
  %{
    name: "Japanese Cucumber",
    description: "Crisp Japanese cucumbers, perfect for sushi or salads. Organically grown.",
    price: Decimal.new("5.50"),
    category: "vegetables",
    expires_at: DateTime.add(DateTime.utc_now(), 8, :day),
    is_active: true,
    user_id: vegetable_vendor.id
  },
  %{
    name: "Rainbow Carrots",
    description: "Colorful heirloom carrots in purple, orange, and yellow. Sweet and crunchy.",
    price: Decimal.new("8.90"),
    category: "vegetables",
    expires_at: DateTime.add(DateTime.utc_now(), 10, :day),
    is_active: true,
    user_id: vegetable_vendor.id
  },
  %{
    name: "Organic Kale",
    description: "Nutritious organic kale leaves. Perfect for smoothies or stir-fry.",
    price: Decimal.new("7.50"),
    category: "vegetables",
    expires_at: DateTime.add(DateTime.utc_now(), 6, :day),
    is_active: true,
    user_id: vegetable_vendor.id
  },
  %{
    name: "Bell Peppers Mix",
    description: "Mixed colored bell peppers - red, yellow, and green. Sweet and crunchy.",
    price: Decimal.new("12.90"),
    category: "vegetables",
    expires_at: DateTime.add(DateTime.utc_now(), 9, :day),
    is_active: true,
    user_id: vegetable_vendor.id
  }
]

# Fruit vendor products
fruit_products = [
  %{
    name: "Musang King Durian",
    description: "Premium Musang King durian from Pahang. Creamy, sweet, and aromatic. Limited stock!",
    price: Decimal.new("95.00"),
    category: "fruits",
    expires_at: DateTime.add(DateTime.utc_now(), 3, :day),
    is_active: true,
    user_id: fruit_vendor.id
  },
  %{
    name: "Dragon Fruit (Red)",
    description: "Sweet red dragon fruit with vibrant color. Rich in antioxidants and vitamin C.",
    price: Decimal.new("14.90"),
    category: "fruits",
    expires_at: DateTime.add(DateTime.utc_now(), 6, :day),
    is_active: true,
    user_id: fruit_vendor.id
  },
  %{
    name: "Cameron Strawberries",
    description: "Fresh strawberries from Cameron Highlands. Sweet and juicy, perfect for desserts.",
    price: Decimal.new("18.50"),
    category: "fruits",
    expires_at: DateTime.add(DateTime.utc_now(), 4, :day),
    is_active: true,
    user_id: fruit_vendor.id
  },
  %{
    name: "Tropical Mango",
    description: "Sweet and juicy Harumanis mangoes. Perfect ripeness for immediate consumption.",
    price: Decimal.new("12.90"),
    category: "fruits",
    expires_at: DateTime.add(DateTime.utc_now(), 5, :day),
    is_active: true,
    user_id: fruit_vendor.id
  },
  %{
    name: "Rambutan (Fresh)",
    description: "Fresh rambutan from local orchards. Sweet and refreshing tropical fruit.",
    price: Decimal.new("8.90"),
    category: "fruits",
    expires_at: DateTime.add(DateTime.utc_now(), 4, :day),
    is_active: true,
    user_id: fruit_vendor.id
  },
  %{
    name: "Passion Fruit",
    description: "Aromatic passion fruits, perfect for drinks or desserts. Very fragrant!",
    price: Decimal.new("16.50"),
    category: "fruits",
    expires_at: DateTime.add(DateTime.utc_now(), 7, :day),
    is_active: true,
    user_id: fruit_vendor.id
  }
]

# Insert all products
all_products = fish_products ++ vegetable_products ++ fruit_products
{created_products, _} = Enum.map_reduce(all_products, [], fn product_attrs, acc ->
  changeset =
    %Product{}
    |> Product.update_changeset(product_attrs)
    |> Ecto.Changeset.put_change(:user_id, product_attrs.user_id)

  case Repo.insert(changeset) do
    {:ok, product} ->
      IO.puts("✅ Created: #{product.name} - RM#{product.price} (#{product.category})")
      {product, [product | acc]}
    {:error, changeset} ->
      IO.puts("❌ Failed to create product: #{inspect(changeset.errors)}")
      {nil, acc}
  end
end)

created_products = Enum.filter(created_products, & &1)

# Create some sample chat messages and conversations
IO.puts("\n💬 Creating sample conversations...")

# Get some products for chat examples
fish_product = Enum.find(created_products, fn p -> p.user_id == fish_vendor.id end)
vegetable_product = Enum.find(created_products, fn p -> p.user_id == vegetable_vendor.id end)
fruit_product = Enum.find(created_products, fn p -> p.user_id == fruit_vendor.id end)

# Create conversations with messages
if fish_product do
  # Customer inquiry about fish
  {:ok, _customer_msg1} = Chat.create_customer_message(fish_product.id, %{
    "content" => "Hi, is this red snapper still fresh? When was it caught?",
    "sender_name" => "John Customer",
    "sender_email" => "#{local_part}+customer1@#{domain}"
  })

  # Vendor reply
  {:ok, _vendor_reply1} = Chat.create_vendor_reply(fish_product.id, fish_vendor.id,
    "Yes, it's very fresh! Caught yesterday morning from Terengganu waters. Still have good stock available.")

  # Another customer message
  {:ok, _customer_msg2} = Chat.create_customer_message(fish_product.id, %{
    "content" => "Great! Can you clean and fillet it for me? I'll pick up this evening.",
    "sender_name" => "John Customer",
    "sender_email" => "#{local_part}+customer1@#{domain}"
  })

  IO.puts("✅ Created conversation for fish product")
end

if vegetable_product do
  # Customer inquiry about vegetables (unresolved)
  {:ok, _customer_msg3} = Chat.create_customer_message(vegetable_product.id, %{
    "content" => "Do you have any pesticide-free lettuce? Looking for organic options for my family.",
    "sender_name" => "Sarah Buyer",
    "sender_email" => "#{local_part}+customer2@#{domain}"
  })

  {:ok, _vendor_reply2} = Chat.create_vendor_reply(vegetable_product.id, vegetable_vendor.id,
    "Yes! All our vegetables are 100% organic and pesticide-free. We have fresh lettuce harvested this morning.")

  {:ok, _customer_msg4} = Chat.create_customer_message(vegetable_product.id, %{
    "content" => "Perfect! How much for 2kg of mixed lettuce?",
    "sender_name" => "Sarah Buyer",
    "sender_email" => "#{local_part}+customer2@#{domain}"
  })

  IO.puts("✅ Created conversation for vegetable product (unresolved)")
end

if fruit_product do
  # Customer inquiry about fruits (will be marked as resolved)
  {:ok, _customer_msg5} = Chat.create_customer_message(fruit_product.id, %{
    "content" => "Is the durian ready to eat? How do I know if it's ripe?",
    "sender_name" => "Ahmad Customer",
    "sender_email" => "#{local_part}+customer3@#{domain}"
  })

  {:ok, _vendor_reply3} = Chat.create_vendor_reply(fruit_product.id, fruit_vendor.id,
    "This durian is perfectly ripe! You can tell by the strong aroma and the natural split lines. Ready to eat immediately.")

  {:ok, _customer_msg6} = Chat.create_customer_message(fruit_product.id, %{
    "content" => "Thank you! I'll take one. Your explanation was very helpful.",
    "sender_name" => "Ahmad Customer",
    "sender_email" => "#{local_part}+customer3@#{domain}"
  })

  # Mark this conversation as resolved
  {:ok, _conversation} = Chat.mark_conversation_resolved(fruit_product.id, fruit_vendor.id)

  IO.puts("✅ Created conversation for fruit product (resolved)")
end

# Create some additional unread messages for testing notifications
if length(created_products) >= 2 do
  random_fish_product = Enum.find(created_products, fn p -> p.user_id == fish_vendor.id and p.id != fish_product.id end)
  random_veg_product = Enum.find(created_products, fn p -> p.user_id == vegetable_vendor.id and p.id != vegetable_product.id end)

  if random_fish_product do
    {:ok, _msg} = Chat.create_customer_message(random_fish_product.id, %{
      "content" => "What's the price for bulk orders? I need fish for a restaurant.",
      "sender_name" => "Restaurant Owner",
      "sender_email" => "restaurant@example.com"
    })
    IO.puts("✅ Created unread message for fish vendor")
  end

  if random_veg_product do
    {:ok, _msg} = Chat.create_customer_message(random_veg_product.id, %{
      "content" => "Do you deliver to Shah Alam? Interested in weekly vegetable supply.",
      "sender_name" => "Weekly Customer",
      "sender_email" => "weekly@example.com"
    })
    IO.puts("✅ Created unread message for vegetable vendor")
  end
end

IO.puts("\n🎉 Database seeding completed successfully!")
IO.puts("\n" <> String.duplicate("=", 60))
IO.puts("📧 LOGIN CREDENTIALS (Password: password123)")
IO.puts(String.duplicate("=", 60))
IO.puts("🔧 Admin:           #{admin_email}")
IO.puts("🐟 Fish Vendor:     #{fish_vendor_email}")
IO.puts("🥬 Vegetable Vendor: #{vegetable_vendor_email}")
IO.puts("🍎 Fruit Vendor:    #{fruit_vendor_email}")
IO.puts(String.duplicate("-", 60))
IO.puts("👥 Sample Customers:")
Enum.each(customers, fn customer ->
  IO.puts("   #{customer.email}")
end)

IO.puts("\n" <> String.duplicate("=", 60))
IO.puts("📊 CREATED DATA SUMMARY")
IO.puts(String.duplicate("=", 60))
IO.puts("👤 Users: #{Repo.aggregate(User, :count, :id)}")
IO.puts("🛒 Products: #{Repo.aggregate(Product, :count, :id)}")
IO.puts("💬 Messages: #{Repo.aggregate(Message, :count, :id)}")
IO.puts("📋 Conversations: #{Repo.aggregate(Conversation, :count, :id)}")

IO.puts("\n🚀 Next steps:")
IO.puts("   1. Start server: mix phx.server")
IO.puts("   2. Visit: http://localhost:4000")
IO.puts("   3. Check emails at: http://localhost:4000/dev/mailbox")
IO.puts("   4. Login with any email above using password: password123")

IO.puts("\n💡 Features to test:")
IO.puts("   ✅ Chat system with notifications")
IO.puts("   ✅ Conversation status (resolved/open)")
IO.puts("   ✅ Vendor product management")
IO.puts("   ✅ Real-time messaging")
IO.puts("   ✅ Admin dashboard")
IO.puts("   ✅ Multiple vendor types (fish, vegetables, fruits)")

IO.puts("\n🔄 To reset data: mix run priv/repo/seeds.exs")
IO.puts("📧 To use different email: SEED_EMAIL=your@email.com mix run priv/repo/seeds.exs")

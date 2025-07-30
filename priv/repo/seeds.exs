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

# Get environment variables for seeding
admin_email = System.get_env("ADMIN_EMAIL", "rroslan@gmail.com")
fish_vendor_email = System.get_env("FISH_VENDOR_EMAIL", "roslanr@gmail.com")
vegetables_vendor_email = System.get_env("VEGETABLES_VENDOR_EMAIL", "rosslann.ramli@gmail.com")
fruits_vendor_email = System.get_env("FRUITS_VENDOR_EMAIL", "dev.rroslan@gmail.com")

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
    is_vendor: true,
    address: "Pasar Borong Selayang, Selangor, Malaysia"
  })

# Update vendor role
fish_vendor =
  fish_vendor
  |> User.role_changeset(%{is_admin: false, is_vendor: true})
  |> Repo.update!()

IO.puts("✅ Created fish vendor: #{fish_vendor.email}")

# Create Vegetables Vendor
vegetables_vendor =
  create_or_update_user.(vegetables_vendor_email, %{
    name: "Fresh Vegetables Vendor",
    email: vegetables_vendor_email,
    is_admin: false,
    is_vendor: true,
    address: "Pasar Chow Kit, Kuala Lumpur, Malaysia"
  })

# Update vendor role
vegetables_vendor =
  vegetables_vendor
  |> User.role_changeset(%{is_admin: false, is_vendor: true})
  |> Repo.update!()

IO.puts("✅ Created vegetables vendor: #{vegetables_vendor.email}")

# Create Fruits Vendor
fruits_vendor =
  create_or_update_user.(fruits_vendor_email, %{
    name: "Fresh Fruits Vendor",
    email: fruits_vendor_email,
    is_admin: false,
    is_vendor: true,
    address: "Pasar Malam Taman Connaught, Cheras, Kuala Lumpur, Malaysia"
  })

# Update vendor role
fruits_vendor =
  fruits_vendor
  |> User.role_changeset(%{is_admin: false, is_vendor: true})
  |> Repo.update!()

IO.puts("✅ Created fruits vendor: #{fruits_vendor.email}")

# Create some sample regular users
sample_users = [
  %{
    name: "John Customer",
    email: "john.customer@example.com",
    is_admin: false,
    is_vendor: false,
    address: "Petaling Jaya, Selangor, Malaysia"
  },
  %{
    name: "Sarah Buyer",
    email: "sarah.buyer@example.com",
    is_admin: false,
    is_vendor: false,
    address: "Shah Alam, Selangor, Malaysia"
  },
  %{
    name: "Ahmad Rahman",
    email: "ahmad.rahman@example.com",
    is_admin: false,
    is_vendor: false,
    address: "Ampang, Kuala Lumpur, Malaysia"
  }
]

Enum.each(sample_users, fn user_attrs ->
  user = create_or_update_user.(user_attrs.email, user_attrs)
  IO.puts("✅ Created sample user: #{user.email}")
end)

IO.puts("\n🎉 Database seeding completed!")
IO.puts("\n📧 Login instructions will be sent via magic links to:")
IO.puts("   Admin: #{admin_email}")
IO.puts("   Fish Vendor: #{fish_vendor_email}")
IO.puts("   Vegetables Vendor: #{vegetables_vendor_email}")
IO.puts("   Fruits Vendor: #{fruits_vendor_email}")

IO.puts("\n🚀 You can now start the application with: mix phx.server")
IO.puts("📬 Magic link emails can be viewed at: http://localhost:4000/dev/mailbox")

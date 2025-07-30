# Script for adding placeholder profile images to existing vendors
#
# Run this script with:
#     mix run priv/repo/add_vendor_images.exs

alias MakananSegar.Repo
alias MakananSegar.Accounts
alias MakananSegar.Accounts.User

IO.puts("🖼️  Adding placeholder profile images for vendors...")

# Helper function to create placeholder image URL
create_placeholder_image = fn name, category ->
  # Using a simple placeholder service that generates avatars
  name_encoded = URI.encode(name)
  background_color =
    case category do
      "fish" -> "1e40af"      # Blue
      "vegetables" -> "16a34a" # Green
      "fruits" -> "ea580c"     # Orange
      _ -> "6366f1"            # Purple
    end

  "https://ui-avatars.com/api/?name=#{name_encoded}&size=200&background=#{background_color}&color=ffffff&bold=true"
end

# Update Fish Vendor Profile
case Accounts.get_user_by_email("roslanr@mail.com") do
  nil ->
    IO.puts("❌ Fish vendor not found")

  user ->
    image_url = create_placeholder_image.("Fresh Ocean Fish Market", "fish")

    user
    |> User.profile_changeset(%{profile_image: image_url})
    |> Repo.update!()

    IO.puts("✅ Updated Fish Vendor profile image")
end

# Update Alternative Fish Vendor Profile
case Accounts.get_user_by_email("roslanr@gmail.com") do
  nil ->
    IO.puts("❌ Alternative fish vendor not found")

  user ->
    image_url = create_placeholder_image.("Sea Breeze Fishmonger", "fish")

    user
    |> User.profile_changeset(%{profile_image: image_url})
    |> Repo.update!()

    IO.puts("✅ Updated Alternative Fish Vendor profile image")
end

# Update Vegetables Vendor Profile
case Accounts.get_user_by_email("rosslann.ramli@mail.com") do
  nil ->
    IO.puts("❌ Vegetables vendor not found")

  user ->
    image_url = create_placeholder_image.("Green Garden Vegetables", "vegetables")

    user
    |> User.profile_changeset(%{profile_image: image_url})
    |> Repo.update!()

    IO.puts("✅ Updated Vegetables Vendor profile image")
end

# Update Fruits Vendor Profile
case Accounts.get_user_by_email("dev.rroslan@gmail.com") do
  nil ->
    IO.puts("❌ Fruits vendor not found")

  user ->
    image_url = create_placeholder_image.("Tropical Fruits Paradise", "fruits")

    user
    |> User.profile_changeset(%{profile_image: image_url})
    |> Repo.update!()

    IO.puts("✅ Updated Fruits Vendor profile image")
end

IO.puts("\n🎉 Vendor profile images updated!")
IO.puts("\n🖼️  All vendors now have profile images:")
IO.puts("   • Fresh Ocean Fish Market (Blue theme)")
IO.puts("   • Sea Breeze Fishmonger (Blue theme)")
IO.puts("   • Green Garden Vegetables (Green theme)")
IO.puts("   • Tropical Fruits Paradise (Orange theme)")
IO.puts("\n📋 Images are generated using ui-avatars.com service")
IO.puts("🔄 Vendors can upload their own images at: /vendor/profile")

# Script for updating existing vendor profiles with business information
#
# Run this script with:
#     mix run priv/repo/update_vendor_profiles.exs

alias MakananSegar.Repo
alias MakananSegar.Accounts
alias MakananSegar.Accounts.User

IO.puts("🔄 Updating vendor profiles with business information...")

# Fish Vendor Profile
case Accounts.get_user_by_email("roslanr@mail.com") do
  nil ->
    IO.puts("❌ Fish vendor not found")

  user ->
    user
    |> User.profile_changeset(%{
      business_name: "Fresh Ocean Fish Market",
      phone: "+60123456789",
      business_description: "Premium fresh fish and seafood from local fishermen. We offer the freshest catch of the day including red snapper, mackerel, prawns, and crabs.",
      business_hours: "Mon-Sat: 6:00 AM - 6:00 PM, Sun: 6:00 AM - 12:00 PM",
      business_type: "fish",
      business_registration_number: "SSM001234567",
      website: "https://freshoceanfish.com.my"
    })
    |> Repo.update!()

    IO.puts("✅ Updated Fish Vendor profile")
end

# Alternative Fish Vendor Profile
case Accounts.get_user_by_email("roslanr@gmail.com") do
  nil ->
    IO.puts("❌ Alternative fish vendor not found")

  user ->
    user
    |> User.profile_changeset(%{
      business_name: "Sea Breeze Fishmonger",
      phone: "+60123456788",
      business_description: "Family-owned fish business serving fresh catches for over 20 years. Specializing in local fish varieties and imported premium seafood.",
      business_hours: "Daily: 5:30 AM - 7:00 PM",
      business_type: "fish",
      business_registration_number: "SSM001234568",
      website: "https://seabreezefish.my"
    })
    |> Repo.update!()

    IO.puts("✅ Updated Alternative Fish Vendor profile")
end

# Vegetables Vendor Profile
case Accounts.get_user_by_email("rosslann.ramli@mail.com") do
  nil ->
    IO.puts("❌ Vegetables vendor not found")

  user ->
    user
    |> User.profile_changeset(%{
      business_name: "Green Garden Vegetables",
      phone: "+60129876543",
      business_description: "Organic and conventional vegetables sourced directly from Cameron Highlands farms. Fresh daily deliveries of leafy greens, root vegetables, and herbs.",
      business_hours: "Mon-Sun: 7:00 AM - 8:00 PM",
      business_type: "vegetables",
      business_registration_number: "SSM002345678",
      website: "https://greengardenveggies.com.my"
    })
    |> Repo.update!()

    IO.puts("✅ Updated Vegetables Vendor profile")
end

# Fruits Vendor Profile
case Accounts.get_user_by_email("dev.rroslan@gmail.com") do
  nil ->
    IO.puts("❌ Fruits vendor not found")

  user ->
    user
    |> User.profile_changeset(%{
      business_name: "Tropical Fruits Paradise",
      phone: "+60187654321",
      business_description: "Premium tropical and seasonal fruits from Malaysian orchards. Featuring durian, mangosteen, rambutan, and imported fruits from around the world.",
      business_hours: "Mon-Sun: 8:00 AM - 10:00 PM",
      business_type: "fruits",
      business_registration_number: "SSM003456789",
      website: "https://tropicalfruits.my"
    })
    |> Repo.update!()

    IO.puts("✅ Updated Fruits Vendor profile")
end

IO.puts("\n🎉 Vendor profile updates completed!")
IO.puts("\n📋 Updated business information includes:")
IO.puts("   • Business names and descriptions")
IO.puts("   • Contact phone numbers")
IO.puts("   • Business hours")
IO.puts("   • Business types and registration numbers")
IO.puts("   • Website URLs")
IO.puts("\n🔗 Vendors can now update their profiles at: /vendor/profile")

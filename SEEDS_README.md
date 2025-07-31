# Seeds Configuration for MakananSegar

This document explains how to use the comprehensive seeds file to set up test data for development and testing.

## Quick Start

### Default Setup
```bash
# Uses default email: test@example.com
mix run priv/repo/seeds.exs
```

### Custom Email Setup
```bash
# Use your own email as the base
SEED_EMAIL=your.email@gmail.com mix run priv/repo/seeds.exs
```

## What Gets Created

### 🔧 Admin Account
- **Email**: `your.email+admin@domain.com`
- **Role**: System Administrator
- **Access**: Full admin dashboard and controls

### 🐟 Fish Vendor
- **Email**: `your.email+fish@domain.com`
- **Business**: Ahmad's Fresh Fish Market
- **Products**: Red Snapper, Tiger Prawns, Sea Bass, Mackerel, Mud Crabs
- **Location**: Pasar Borong Selayang, Selangor

### 🥬 Vegetable Vendor
- **Email**: `your.email+vegetables@domain.com`
- **Business**: Siti's Organic Vegetables
- **Products**: Baby Spinach, Cherry Tomatoes, Japanese Cucumber, Rainbow Carrots, Kale, Bell Peppers
- **Location**: Cameron Highlands, Pahang

### 🍎 Fruit Vendor
- **Email**: `your.email+fruits@domain.com`
- **Business**: Lim's Tropical Fruits
- **Products**: Musang King Durian, Dragon Fruit, Strawberries, Mango, Rambutan, Passion Fruit
- **Location**: Pasar Malam Taman Connaught, Cheras, KL

### 👥 Sample Customers
- `your.email+customer1@domain.com` - John Customer
- `your.email+customer2@domain.com` - Sarah Buyer
- `your.email+customer3@domain.com` - Ahmad Customer

## Test Data Features

### 💬 Pre-created Conversations
1. **Fish Product Chat** - Customer asking about freshness (open conversation)
2. **Vegetable Product Chat** - Customer asking about organic options (unread messages)
3. **Fruit Product Chat** - Customer asking about durian ripeness (resolved conversation)

### 🔔 Notification Testing
- Fish vendor has 2 unread messages
- Vegetable vendor has 2 unread messages
- Fruit vendor has 1 resolved conversation (no notifications)

### 📊 Products Variety
- **17 total products** across 3 categories
- Different price ranges (RM5.50 - RM95.00)
- Various expiry dates for testing urgency
- Realistic Malaysian product descriptions

## Login Information

**Password for all accounts**: `password123`

### Email Examples (if using `john@gmail.com`)
- Admin: `john+admin@gmail.com`
- Fish Vendor: `john+fish@gmail.com`
- Vegetable Vendor: `john+vegetables@gmail.com`
- Fruit Vendor: `john+fruits@gmail.com`
- Customer 1: `john+customer1@gmail.com`

## Testing Scenarios

### 🔴 Chat Notifications
1. Login as any vendor
2. See red notification badges on product cards
3. Click chat button to view messages
4. Mark conversations as resolved/reopened

### 📱 Conversation Management
1. Login as fruit vendor (`your.email+fruits@domain.com`)
2. Notice resolved conversation (green checkmark)
3. Login as fish/vegetable vendor
4. See open conversations with unread messages

### 🛒 Product Management
1. Login as any vendor
2. View your products in vendor dashboard
3. Edit product details
4. Add new products

### 👨‍💼 Admin Features
1. Login as admin (`your.email+admin@domain.com`)
2. Access admin dashboard
3. View all users and products
4. Manage system settings

## Reset Data

```bash
# Clean and recreate all data
mix run priv/repo/seeds.exs
```

## Environment Variables

Add to your `.env` file:
```bash
# Base email for creating test accounts
SEED_EMAIL=your.email@domain.com
```

## Real-world Testing

The seeds create realistic Malaysian marketplace data:

- **Authentic product names** (Musang King durian, Harumanis mango)
- **Real locations** (Cameron Highlands, Pasar Borong Selayang)
- **Local context** (Malaysian addresses, phone numbers)
- **Cultural relevance** (Sambal recipes, tom yam suggestions)

## Development Workflow

1. **Setup**: Run seeds to create test environment
2. **Test Features**: Use different vendor accounts to test functionality
3. **Reset**: Re-run seeds when you need fresh data
4. **Deploy**: Seeds are safe to run multiple times

## Troubleshooting

### Seeds Won't Run
```bash
# Ensure database is migrated
mix ecto.migrate

# Then run seeds
mix run priv/repo/seeds.exs
```

### Email Conflicts
If you get email conflicts, the seeds will clean all existing data first.

### Missing Products
If products don't appear, check that the vendor accounts were created successfully in the logs.

## Production Notes

⚠️ **Warning**: This seeds file is designed for development only. It:
- Deletes ALL existing data
- Creates test accounts with simple passwords
- Should NOT be run in production

For production data setup, create a separate migration script.
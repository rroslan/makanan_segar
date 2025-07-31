# MakananSegar System Documentation

## Table of Contents
1. [Overview](#overview)
2. [Database Structure](#database-structure)
3. [Conversation Management System](#conversation-management-system)
4. [Chat & Notification System](#chat--notification-system)
5. [User Management & Roles](#user-management--roles)
6. [Product Management](#product-management)
7. [Seeds & Testing](#seeds--testing)
8. [API Reference](#api-reference)
9. [Development Workflow](#development-workflow)

---

## Overview

MakananSegar is a fresh produce marketplace platform built with Phoenix LiveView, enabling vendors to sell fresh products and customers to purchase them. The system features real-time chat, conversation management, and intelligent notifications.

### Key Features
- **Multi-vendor marketplace** for fresh produce
- **Real-time chat system** between customers and vendors
- **Conversation status management** (open/resolved)
- **Smart notification system** with persistent read tracking
- **Role-based access control** (Admin, Vendor, Customer)
- **Product lifecycle management** with expiry tracking
- **Comprehensive testing environment** with seeds

### Technology Stack
- **Backend**: Elixir/Phoenix Framework
- **Frontend**: Phoenix LiveView with TailwindCSS & DaisyUI
- **Database**: PostgreSQL with Ecto ORM
- **Real-time**: Phoenix PubSub for live updates
- **Authentication**: Built-in Phoenix authentication

---

## Database Structure

### Core Tables

#### Users Table
```sql
CREATE TABLE users (
  id BIGSERIAL PRIMARY KEY,
  name VARCHAR(255),
  email VARCHAR(255) NOT NULL UNIQUE,
  is_admin BOOLEAN DEFAULT FALSE,
  is_vendor BOOLEAN DEFAULT FALSE,
  confirmed_at TIMESTAMP,
  address TEXT,
  phone VARCHAR(50),
  business_name VARCHAR(255),
  business_description TEXT,
  business_type VARCHAR(100),
  business_hours VARCHAR(255),
  website VARCHAR(255),
  profile_image VARCHAR(500),
  inserted_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL
);
```

**Key Relationships:**
- One-to-many with `products` (vendors can have multiple products)
- One-to-many with `chat_messages` (users can send multiple messages)
- One-to-many with `conversations` (via resolved_by_user_id)

#### Products Table
```sql
CREATE TABLE products (
  id BIGSERIAL PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  description TEXT,
  category VARCHAR(100) NOT NULL,
  price DECIMAL(10,2) NOT NULL,
  user_id BIGINT REFERENCES users(id) ON DELETE CASCADE,
  expires_at TIMESTAMP,
  is_active BOOLEAN DEFAULT TRUE,
  image VARCHAR(500),
  inserted_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL
);
```

**Categories:** `fish`, `vegetables`, `fruits`

#### Chat Messages Table
```sql
CREATE TABLE chat_messages (
  id BIGSERIAL PRIMARY KEY,
  content TEXT NOT NULL,
  sender_name VARCHAR(255),
  sender_email VARCHAR(255),
  product_id BIGINT REFERENCES products(id) ON DELETE CASCADE,
  user_id BIGINT REFERENCES users(id) ON DELETE SET NULL,
  is_vendor_reply BOOLEAN DEFAULT FALSE,
  inserted_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL
);
```

**Message Types:**
- **Customer Messages**: `is_vendor_reply = false`, may have `sender_name`/`sender_email` for guests
- **Vendor Replies**: `is_vendor_reply = true`, requires `user_id`

#### Conversations Table
```sql
CREATE TABLE conversations (
  id BIGSERIAL PRIMARY KEY,
  product_id BIGINT REFERENCES products(id) ON DELETE CASCADE,
  status VARCHAR(50) DEFAULT 'open' CHECK (status IN ('open', 'resolved')),
  resolved_at TIMESTAMP,
  resolved_by_user_id BIGINT REFERENCES users(id) ON DELETE SET NULL,
  inserted_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL,
  UNIQUE(product_id)
);
```

**Status Flow:**
- `open` → `resolved` (when vendor marks as resolved)
- `resolved` → `open` (when vendor reopens)

#### Message Reads Table
```sql
CREATE TABLE message_reads (
  id BIGSERIAL PRIMARY KEY,
  message_id BIGINT REFERENCES chat_messages(id) ON DELETE CASCADE,
  user_id BIGINT REFERENCES users(id) ON DELETE CASCADE,
  read_at TIMESTAMP NOT NULL,
  inserted_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL,
  UNIQUE(message_id, user_id)
);
```

**Purpose:** Track which users have read which messages for persistent notification management.

### Database Relationships

```
Users (1) ──── (N) Products
  │                  │
  │                  │
  └── (N) Messages ──┘
  │       │
  │       └── (N) MessageReads
  │
  └── (N) Conversations (via resolved_by_user_id)
              │
              └── (1) Product
```

### Indexes and Constraints

#### Performance Indexes
```sql
-- Chat message queries
CREATE INDEX chat_messages_product_id_index ON chat_messages(product_id);
CREATE INDEX chat_messages_user_id_index ON chat_messages(user_id);
CREATE INDEX chat_messages_product_id_inserted_at_index ON chat_messages(product_id, inserted_at);

-- Conversation queries
CREATE INDEX conversations_product_id_index ON conversations(product_id);
CREATE INDEX conversations_status_index ON conversations(status);
CREATE INDEX conversations_product_id_status_index ON conversations(product_id, status);

-- Message read tracking
CREATE INDEX message_reads_message_id_index ON message_reads(message_id);
CREATE INDEX message_reads_user_id_index ON message_reads(user_id);
```

#### Data Integrity Constraints
```sql
-- Conversation status validation
ALTER TABLE conversations ADD CONSTRAINT valid_status 
  CHECK (status IN ('open', 'resolved'));

-- Resolved conversations must have resolved_at and resolved_by_user_id
ALTER TABLE conversations ADD CONSTRAINT resolved_fields_consistency 
  CHECK (
    (status = 'resolved' AND resolved_at IS NOT NULL AND resolved_by_user_id IS NOT NULL) OR 
    (status = 'open' AND resolved_at IS NULL AND resolved_by_user_id IS NULL)
  );
```

---

## Conversation Management System

### Architecture Overview

The conversation management system tracks the lifecycle of customer-vendor interactions, allowing vendors to organize and manage customer service efficiently.

### Core Components

#### 1. Conversation Schema (`MakananSegar.Chat.Conversation`)

```elixir
defmodule MakananSegar.Chat.Conversation do
  schema "conversations" do
    field :status, :string, default: "open"
    field :resolved_at, :utc_datetime
    
    belongs_to :product, Product
    belongs_to :resolved_by_user, User, foreign_key: :resolved_by_user_id
    
    timestamps(type: :utc_datetime)
  end
end
```

**Key Functions:**
- `mark_resolved_changeset/2` - Mark conversation as resolved
- `reopen_changeset/1` - Reopen resolved conversation
- `resolved?/1` - Check if conversation is resolved
- `open?/1` - Check if conversation is open

#### 2. Chat Context Functions

```elixir
# Conversation Management
Chat.get_or_create_conversation(product_id)
Chat.mark_conversation_resolved(product_id, vendor_user_id)
Chat.reopen_conversation(product_id, vendor_user_id)
Chat.get_conversations_status(product_ids)

# Smart Notification Queries
Chat.get_vendor_unread_counts_by_product_open_only(vendor_user_id)
```

### Conversation Lifecycle

#### 1. Creation
```
Customer sends message → Conversation auto-created as "open"
```

#### 2. Resolution
```
Vendor clicks "Mark Resolved" → Status: "resolved"
                              → resolved_at: timestamp
                              → resolved_by_user_id: vendor_id
                              → Notifications: hidden
```

#### 3. Reopening
```
Vendor clicks "Reopen" → Status: "open"
                       → resolved_at: null
                       → resolved_by_user_id: null
                       → Notifications: visible again
```

### UI Integration

#### Vendor Chat Header
```heex
<%= if @conversation_status == "resolved" do %>
  <button phx-click="reopen_conversation">Reopen</button>
  <div class="badge badge-success">Resolved</div>
<% else %>
  <button phx-click="mark_conversation_resolved">Mark Resolved</button>
  <div class="badge badge-info">Open</div>
<% end %>
```

#### Product Card Indicators
```heex
<!-- Chat notification badge (only for open conversations) -->
<%= if Map.get(@unread_counts, product.id, 0) > 0 do %>
  <div class="badge badge-error">{unread_count}</div>
<% end %>

<!-- Resolved conversation indicator -->
<%= if Map.get(@conversation_statuses, product.id) == "resolved" do %>
  <div class="badge badge-success">✓</div>
<% end %>
```

---

## Chat & Notification System

### Real-time Architecture

#### PubSub Topics
```elixir
# Product-specific chat updates
"product_chat:{product_id}"

# Vendor-wide chat notifications
"vendor_chats:{vendor_user_id}"
```

#### Message Flow
```
Customer sends message → Chat.create_customer_message()
                      → Broadcast to "product_chat:{product_id}"
                      → Broadcast to "vendor_chats:{vendor_id}"
                      → Update notification counts
                      → UI updates in real-time
```

### Notification Logic

#### Smart Notification Rules
1. **Only open conversations** generate notifications
2. **Resolved conversations** are hidden from notification counts
3. **Session-based clearing** for immediate feedback
4. **Database persistence** for permanent read tracking

#### Notification Count Queries
```elixir
# Only count unread messages in open conversations
def get_vendor_unread_counts_by_product_open_only(vendor_user_id) do
  from(m in Message,
    join: p in assoc(m, :product),
    left_join: c in Conversation, on: c.product_id == p.id,
    where: p.user_id == ^vendor_user_id and m.is_vendor_reply == false,
    where: is_nil(c.id) or c.status == "open",
    group_by: m.product_id,
    select: {m.product_id, count()}
  )
  |> Repo.all()
  |> Enum.into(%{})
end
```

### Message Types & Handling

#### Customer Messages
- **Authenticated users**: `user_id` set, no sender fields needed
- **Guest users**: `sender_name` and `sender_email` required
- **Always**: `is_vendor_reply = false`

#### Vendor Replies
- **Always authenticated**: `user_id` required
- **Always**: `is_vendor_reply = true`
- **Validation**: Must own the product being discussed

---

## User Management & Roles

### Role System

#### User Types
1. **Admin** (`is_admin: true`)
   - Full system access
   - User management
   - System configuration

2. **Vendor** (`is_vendor: true`)
   - Product management
   - Chat with customers
   - Conversation management
   - Order fulfillment

3. **Customer** (`is_admin: false, is_vendor: false`)
   - Browse products
   - Chat with vendors
   - Place orders

### Authentication Flow

#### Magic Link Authentication
```elixir
# User requests login
Accounts.deliver_user_confirmation_instructions(user, &url/1)

# User clicks email link
UserAuth.log_in_user_from_token(conn, token)
```

#### Permission Checks
```elixir
# Route-level protection
live_session :require_authenticated_user,
  on_mount: [{UserAuth, :ensure_authenticated}]

# Component-level checks
<%= if @current_user && @current_user.is_vendor do %>
  <!-- Vendor-only content -->
<% end %>
```

### Business Profile Management

#### Vendor Profile Fields
- `business_name` - Display name for business
- `business_description` - Marketing description
- `business_type` - Category (fish, vegetables, fruits)
- `business_hours` - Operating schedule
- `website` - External website URL
- `profile_image` - Business logo/photo

---

## Product Management

### Product Lifecycle

#### States
1. **Active** (`is_active: true`) - Available for purchase
2. **Inactive** (`is_active: false`) - Hidden from customers
3. **Expired** (`expires_at < now()`) - Past expiry date

#### Categories
- `fish` - Fresh seafood and fish products
- `vegetables` - Fresh vegetables and herbs
- `fruits` - Fresh fruits and tropical produce

### Expiry Management

#### Expiry Logic
```elixir
def expired?(product) do
  case product.expires_at do
    nil -> false
    expires_at -> DateTime.compare(expires_at, DateTime.utc_now()) == :lt
  end
end
```

#### UI Indicators
```elixir
def format_time_until_expiry(expires_at) do
  case DateTime.diff(expires_at, DateTime.utc_now(), :hour) do
    hours when hours <= 0 -> "Expired"
    hours when hours <= 24 -> "#{hours} hours"
    hours -> "#{div(hours, 24)} days"
  end
end
```

---

## Seeds & Testing

### Seeds Configuration

#### Environment Setup
```bash
# Default setup
mix run priv/repo/seeds.exs

# Custom email domain
SEED_EMAIL=your@domain.com mix run priv/repo/seeds.exs
```

#### Generated Accounts
```
Base: your@domain.com

Admin:     your+admin@domain.com
Fish:      your+fish@domain.com
Vegetables: your+vegetables@domain.com
Fruits:    your+fruits@domain.com
Customer1: your+customer1@domain.com
Customer2: your+customer2@domain.com
Customer3: your+customer3@domain.com
```

### Test Data Structure

#### Products Created
- **Fish Vendor**: 5 products (Red Snapper, Tiger Prawns, Sea Bass, Mackerel, Mud Crabs)
- **Vegetable Vendor**: 6 products (Baby Spinach, Cherry Tomatoes, Cucumber, Carrots, Kale, Bell Peppers)
- **Fruit Vendor**: 6 products (Musang King Durian, Dragon Fruit, Strawberries, Mango, Rambutan, Passion Fruit)

#### Conversation States
1. **Fish Vendor**: 2 unread messages (notifications visible)
2. **Vegetable Vendor**: 2 unread messages (notifications visible)
3. **Fruit Vendor**: 1 resolved conversation (no notifications)

### Data Reset Workflow
```bash
# Clean all data and recreate
mix run priv/repo/seeds.exs

# Verify creation
mix ecto.migrate
mix phx.server
```

---

## API Reference

### Chat Context Functions

#### Message Management
```elixir
# Create customer message
Chat.create_customer_message(product_id, %{
  "content" => "Message content",
  "sender_name" => "Customer Name", # For guests
  "sender_email" => "email@domain.com" # For guests
})

# Create vendor reply
Chat.create_vendor_reply(product_id, vendor_user_id, content)

# List product messages
Chat.list_product_messages(product_id)
```

#### Conversation Management
```elixir
# Get or create conversation
{:ok, conversation} = Chat.get_or_create_conversation(product_id)

# Mark as resolved
{:ok, conversation} = Chat.mark_conversation_resolved(product_id, vendor_user_id)

# Reopen conversation
{:ok, conversation} = Chat.reopen_conversation(product_id, vendor_user_id)

# Get status for multiple products
statuses = Chat.get_conversations_status([product_id1, product_id2])
```

#### Notification Queries
```elixir
# Get unread counts (all conversations)
counts = Chat.get_vendor_unread_counts_by_product(vendor_user_id)

# Get unread counts (open conversations only)
counts = Chat.get_vendor_unread_counts_by_product_open_only(vendor_user_id)
```

#### Real-time Subscriptions
```elixir
# Subscribe to product chat
Chat.subscribe_to_product_chat(product_id)

# Subscribe to vendor notifications
Chat.subscribe_to_vendor_chats(vendor_user_id)

# Unsubscribe
Chat.unsubscribe_from_product_chat(product_id)
```

### LiveView Event Handlers

#### Chat Events
```elixir
# Send message
def handle_event("send_chat_message", params, socket)

# Mark conversation resolved
def handle_event("mark_conversation_resolved", %{"product-id" => product_id}, socket)

# Reopen conversation
def handle_event("reopen_conversation", %{"product-id" => product_id}, socket)
```

#### Real-time Updates
```elixir
# New message received
def handle_info({:message_created, message}, socket)

# Vendor notification update
def handle_info({:new_customer_message, message}, socket)
```

---

## Development Workflow

### Setup Process
```bash
# 1. Clone and setup
git clone <repository>
cd makanan_segar
mix deps.get

# 2. Database setup
mix ecto.create
mix ecto.migrate

# 3. Seed test data
SEED_EMAIL=your@email.com mix run priv/repo/seeds.exs

# 4. Start development server
mix phx.server
```

### Testing Workflow

#### Chat System Testing
1. Login as customer (`your+customer1@domain.com`)
2. Send message to any vendor product
3. Login as vendor (e.g., `your+fish@domain.com`)
4. See notification badge on product card
5. Click chat button to view messages
6. Send reply as vendor
7. Mark conversation as resolved
8. Verify notification disappears
9. Test reopening conversation

#### Notification System Testing
1. Login as vendor with unread messages
2. Notice red notification badges
3. Click chat to view messages
4. Mark as resolved
5. Refresh page - verify no notifications
6. Reopen conversation
7. Verify notifications return

### Production Deployment

#### Environment Variables
```bash
# Required
DATABASE_URL=postgresql://...
SECRET_KEY_BASE=...
PHX_HOST=yourdomain.com

# Optional
SEED_EMAIL=admin@yourdomain.com
```

#### Migration Commands
```bash
# Run migrations
mix ecto.migrate

# DO NOT run seeds in production
# mix run priv/repo/seeds.exs  # Development only!
```

### Troubleshooting

#### Common Issues

**Chat not updating in real-time**
- Check WebSocket connection in browser dev tools
- Verify PubSub subscriptions are active
- Ensure LiveView is connected (not just mounted)

**Notifications not clearing**
- Check conversation status in database
- Verify notification query includes status filter
- Clear browser cache and test again

**Seeds failing**
- Ensure database is migrated: `mix ecto.migrate`
- Check for conflicting data: Seeds clean all data first
- Verify environment variables if using custom email

#### Debug Commands
```bash
# Check database state
mix ecto.psql

# View logs
tail -f _build/dev/lib/makanan_segar/priv/static/phoenix.log

# Reset everything
mix ecto.drop && mix ecto.create && mix ecto.migrate && mix run priv/repo/seeds.exs
```

---

This documentation provides a complete reference for the MakananSegar marketplace system, covering all aspects from database design to development workflows. For specific implementation details, refer to the source code and inline documentation.
# MakananSegar - Fresh Food Marketplace

MakananSegar is a Phoenix LiveView application that connects local fresh food vendors with customers in Malaysia. The platform enables vendors to list their fresh products (fish, vegetables, fruits) and customers to discover and purchase fresh, locally-sourced food.

## Table of Contents

- [Features](#features)
- [Technical Stack](#technical-stack)
- [Architecture Overview](#architecture-overview)
- [Chat System](#chat-system)
- [Installation](#installation)
- [Configuration](#configuration)
- [Database Schema](#database-schema)
- [Authentication System](#authentication-system)
- [User Roles & Permissions](#user-roles--permissions)
- [Key Modules](#key-modules)
- [API Endpoints & Routes](#api-endpoints--routes)
- [LiveView Components](#liveview-components)
- [Background Jobs](#background-jobs)
- [Testing](#testing)
- [Deployment](#deployment)

## Features

### For Customers
- Browse fresh products without registration
- **Chat with vendors about products as guest users** (no login required)
- View product details, expiry dates, and vendor information
- Filter products by category (fish, vegetables, fruits)
- View vendor profiles and their product listings
- Secure magic link authentication for purchases

### For Vendors
- Vendor dashboard with sales analytics
- **Real-time chat management with customers**
- **Notification badges for unread customer messages**
- **Conversation status management (open/resolved)**
- Product management (CRUD operations)
- Real-time inventory tracking
- Expiry date monitoring and alerts
- Business profile customization
- Product categorization and pricing

### For Administrators
- User management dashboard
- Vendor approval system
- Platform-wide analytics
- Content moderation capabilities

### Platform Features
- **Real-time chat system with Phoenix PubSub**
- **Guest user chat support (no registration required)**
- Real-time updates using Phoenix LiveView
- Responsive design with DaisyUI (Tailwind CSS)
- Dark/light theme support
- Malaysia timezone support
- Automatic product expiry handling
- Background job processing with Oban

## Technical Stack

- **Framework**: Phoenix 1.8.0-rc.4 with LiveView 1.1.0
- **Language**: Elixir 1.18.3 / Erlang 27
- **Database**: PostgreSQL
- **CSS Framework**: Tailwind CSS with DaisyUI
- **Background Jobs**: Oban
- **Authentication**: Magic link (passwordless)
- **Email**: Swoosh with local/production adapters

## Architecture Overview

### Directory Structure

```
makanan_segar/
├── lib/
│   ├── makanan_segar/
│   │   ├── accounts/           # User authentication & management
│   │   ├── products/           # Product domain logic
│   │   ├── workers/            # Background job workers
│   │   └── application.ex      # Application supervision tree
│   └── makanan_segar_web/
│       ├── controllers/        # Traditional Phoenix controllers
│       ├── live/              # LiveView modules
│       │   ├── admin/         # Admin-specific LiveViews
│       │   ├── public_live/   # Public-facing LiveViews
│       │   └── vendor/        # Vendor-specific LiveViews
│       ├── components/        # Reusable UI components
│       └── router.ex          # Application routing
├── priv/
│   ├── repo/migrations/       # Database migrations
│   └── static/               # Static assets
└── test/                     # Test files
```

### Key Design Patterns

1. **Context-based Architecture**: Business logic is organized into contexts (Accounts, Products, Chat)
2. **LiveView for Real-time UI**: Interactive features without JavaScript
3. **Component-based UI**: Reusable function components for consistent UI
4. **Role-based Access Control**: Middleware-based authentication and authorization
5. **Event-driven Updates**: PubSub for real-time synchronization
6. **Guest-friendly Design**: Core features accessible without authentication
7. **Real-time Messaging**: Phoenix PubSub for instant chat delivery

## Chat System

### Overview

MakananSegar features a comprehensive real-time chat system that allows **unauthenticated guests** to communicate directly with vendors about products. This removes barriers to customer engagement and enables immediate product inquiries.

### Guest User Chat Flow

#### 1. **Product Discovery & Chat Access**
- Guests browse products without registration
- Each product card displays vendor information
- Click product to open modal with chat interface
- No authentication required to start conversations

#### 2. **Guest Message Creation**
```elixir
# Guest provides basic contact information
%{
  "content" => "Is this fish still fresh?",
  "sender_name" => "John Customer", 
  "sender_email" => "john@example.com"  # Optional
}
```

#### 3. **Real-time Communication**
- Messages appear instantly via Phoenix PubSub
- Vendors receive notification badges on product cards
- Chat history preserved for ongoing conversations
- Both parties can exchange multiple messages

### Database Schema for Chat

```sql
-- Chat Messages
CREATE TABLE chat_messages (
  id BIGSERIAL PRIMARY KEY,
  product_id BIGINT REFERENCES products(id),
  user_id BIGINT REFERENCES users(id), -- NULL for guest messages
  content TEXT NOT NULL,
  sender_name VARCHAR(255),  -- Guest name
  sender_email VARCHAR(255), -- Guest email (optional)
  is_vendor_reply BOOLEAN DEFAULT FALSE,
  inserted_at TIMESTAMP,
  updated_at TIMESTAMP
);

-- Conversations
CREATE TABLE conversations (
  id BIGSERIAL PRIMARY KEY,
  product_id BIGINT REFERENCES products(id) UNIQUE,
  status VARCHAR(20) DEFAULT 'open', -- 'open' or 'resolved'
  resolved_at TIMESTAMP,
  resolved_by_user_id BIGINT REFERENCES users(id),
  inserted_at TIMESTAMP,
  updated_at TIMESTAMP
);

-- Message Read Tracking
CREATE TABLE message_reads (
  id BIGSERIAL PRIMARY KEY,
  message_id BIGINT REFERENCES chat_messages(id),
  user_id BIGINT REFERENCES users(id),
  read_at TIMESTAMP,
  inserted_at TIMESTAMP
);
```

### Chat Features

#### **For Guest Users**
- **No registration required** - Start chatting immediately
- Provide name for identification
- Optional email for vendor follow-up
- View complete chat history
- Real-time message delivery

#### **For Vendors**
- **Real-time notifications** - Red badges for unread messages
- **Product-specific chats** - Organized by product
- **Conversation management** - Mark conversations as resolved
- **Guest identification** - See guest names in chat
- **Notification persistence** - Badges remain until viewed

#### **Chat Interface Components**

```elixir
# Chat Component Usage
<.live_component 
  module={ProductChatComponent}
  id={"product-chat-#{product.id}"}
  product={product}
  current_user={current_user} # Can be nil for guests
/>
```

### Implementation Details

#### **Guest Message Creation**
```elixir
# lib/makanan_segar/chat.ex
def create_customer_message(product_id, attrs) do
  attrs =
    attrs
    |> Map.put("product_id", product_id)
    |> Map.put("is_vendor_reply", false)
  
  create_message(attrs)
end
```

#### **Message Display Logic**
```elixir
# lib/makanan_segar/chat/message.ex
def display_sender_name(%Message{} = message) do
  cond do
    message.user && message.user.name -> message.user.name
    message.user && message.user.email -> message.user.email
    message.sender_name -> message.sender_name      # Guest name
    message.sender_email -> message.sender_email    # Guest email
    true -> "Anonymous"
  end
end
```

#### **Real-time Updates**
```elixir
# Broadcast to product-specific channel
Phoenix.PubSub.broadcast(
  MakananSegar.PubSub,
  "product_chat:#{product_id}",
  {:message_created, message}
)

# Notify vendor of customer message
Phoenix.PubSub.broadcast(
  MakananSegar.PubSub, 
  "vendor_chats:#{vendor_user_id}",
  {:new_customer_message, message}
)
```

### Real-time Communication Architecture

#### **Phoenix PubSub Integration**

The chat system leverages Phoenix PubSub for real-time message delivery across multiple channels:

```elixir
# Application supervision tree includes PubSub
children = [
  MakananSegar.Repo,
  MakananSegarWeb.Endpoint,
  {Phoenix.PubSub, name: MakananSegar.PubSub},  # PubSub server
  # ... other children
]
```

#### **Channel Structure**

```elixir
# Product-specific chat channels
"product_chat:#{product_id}"     # All participants (guests, vendors)
"vendor_chats:#{vendor_user_id}" # Vendor notifications only

# Subscription in LiveView
def mount(%{"product_id" => product_id}, _session, socket) do
  if connected?(socket) do
    Phoenix.PubSub.subscribe(MakananSegar.PubSub, "product_chat:#{product_id}")
  end
  {:ok, socket}
end
```

#### **Message Broadcasting Flow**

```elixir
# 1. Message created
{:ok, message} = Chat.create_customer_message(product_id, attrs)

# 2. Broadcast to product chat (all participants)
Phoenix.PubSub.broadcast(
  MakananSegar.PubSub,
  "product_chat:#{product_id}",
  {:message_created, message}
)

# 3. Broadcast to vendor notifications (unread counts)
Phoenix.PubSub.broadcast(
  MakananSegar.PubSub, 
  "vendor_chats:#{vendor_user_id}",
  {:new_customer_message, message}
)

# 4. LiveViews receive and update UI
def handle_info({:message_created, message}, socket) do
  updated_messages = socket.assigns.messages ++ [message]
  {:noreply, assign(socket, :messages, updated_messages)}
end
```

#### **Notification Badge System**

```elixir
# Real-time unread count updates
def handle_info({:new_customer_message, _message}, socket) do
  vendor_id = socket.assigns.current_user.id
  unread_counts = Chat.get_vendor_unread_counts_by_product_open_only(vendor_id)
  
  {:noreply, assign(socket, :unread_counts, unread_counts)}
end

# Badge clearing when vendor views chat
def handle_event("view_product", %{"id" => product_id}, socket) do
  vendor_id = socket.assigns.current_user.id
  Chat.mark_messages_as_read(product_id, vendor_id)
  # ... update UI
end
```

### Vendor Notification System

#### **Product Card Indicators**
```html
<!-- Vendor Dashboard - Product Card -->
<button phx-click="view_product" phx-value-id={product.id}>
  <span>Customer Messages</span>
  
  <!-- Unread message badge -->
  <%= if unread_count > 0 do %>
    <div class="badge badge-error">{unread_count}</div>
  <% end %>
  
  <!-- Resolved conversation indicator -->
  <%= if conversation_status == "resolved" do %>
    <div class="badge badge-success">✓</div>
  <% end %>
</button>
```

#### **Conversation Status Management**
```elixir
# Mark conversation as resolved
def mark_conversation_resolved(product_id, vendor_user_id) do
  conversation = get_or_create_conversation(product_id)
  
  Repo.update(conversation, %{
    status: "resolved",
    resolved_at: DateTime.utc_now(),
    resolved_by_user_id: vendor_user_id
  })
end

# Reopen resolved conversation
def reopen_conversation(product_id, _vendor_user_id) do
  conversation = get_conversation_by_product(product_id)
  
  Repo.update(conversation, %{
    status: "open",
    resolved_at: nil,
    resolved_by_user_id: nil
  })
end
```

### Sample Guest Interactions

The seeds file includes realistic guest conversations:

```elixir
# Fish product inquiry
Chat.create_customer_message(fish_product.id, %{
  "content" => "Hi, is this red snapper still fresh? When was it caught?",
  "sender_name" => "John Customer",
  "sender_email" => "john+customer1@gmail.com"
})

# Vendor response
Chat.create_vendor_reply(fish_product.id, fish_vendor.id,
  "Yes, it's very fresh! Caught yesterday morning from Terengganu waters.")

# Follow-up question
Chat.create_customer_message(fish_product.id, %{
  "content" => "Great! Can you clean and fillet it for me?",
  "sender_name" => "John Customer",
  "sender_email" => "john+customer1@gmail.com"
})
```

### UI/UX Considerations

#### **Accessibility**
- Clear visual distinction between guest and vendor messages
- Intuitive chat interface with familiar messaging patterns
- Responsive design for mobile chat experience
- Loading states and error handling

#### **Guest Experience**
- Minimal friction - no signup required
- Clear call-to-action on product cards
- Professional chat interface builds trust
- Vendor response encourages engagement

#### **Vendor Experience**  
- Clear notification system prevents missed messages
- Easy conversation management
- Guest identification helps personalize responses
- Resolved status reduces notification noise

## Installation

```bash
# Clone the repository
git clone <repository-url>
cd makanan_segar

# Install dependencies
mix deps.get

# Create and migrate database
mix ecto.setup

# Install Node.js dependencies
cd assets && npm install && cd ..

# Start Phoenix server
mix phx.server
```

Visit [`localhost:4000`](http://localhost:4000) from your browser.

## Configuration

### Environment Variables

```bash
# Database
DATABASE_URL=postgresql://user:pass@localhost/makanan_segar_dev

# Email (Production)
SMTP_SERVER=smtp.example.com
SMTP_PORT=587
SMTP_USERNAME=your-username
SMTP_PASSWORD=your-password

# Application
PHX_HOST=your-domain.com
SECRET_KEY_BASE=your-secret-key-base
```

### Development Configuration

```elixir
# config/dev.exs
config :makanan_segar, MakananSegarWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4000],
  debug_errors: true,
  code_reloader: true,
  check_origin: false

# Local email adapter (view emails at /dev/mailbox)
config :makanan_segar, MakananSegar.Mailer,
  adapter: Swoosh.Adapters.Local
```

## Database Schema

### Users Table
```sql
CREATE TABLE users (
  id BIGSERIAL PRIMARY KEY,
  email VARCHAR(255) NOT NULL UNIQUE,
  name VARCHAR(255),
  address TEXT,
  profile_image VARCHAR(255),
  is_admin BOOLEAN DEFAULT FALSE,
  is_vendor BOOLEAN DEFAULT FALSE,
  confirmed_at TIMESTAMP,
  -- Vendor-specific fields
  business_name VARCHAR(255),
  phone VARCHAR(255),
  business_description TEXT,
  business_hours JSONB,
  business_type VARCHAR(255),
  business_registration_number VARCHAR(255),
  website VARCHAR(255),
  social_media JSONB,
  inserted_at TIMESTAMP,
  updated_at TIMESTAMP
);
```

### Products Table
```sql
CREATE TABLE products (
  id BIGSERIAL PRIMARY KEY,
  user_id BIGINT REFERENCES users(id),
  name VARCHAR(255) NOT NULL,
  description TEXT,
  category VARCHAR(50) NOT NULL, -- fish, vegetables, fruits
  price DECIMAL(10,2) NOT NULL,
  image VARCHAR(255),
  expires_at TIMESTAMP NOT NULL,
  is_active BOOLEAN DEFAULT TRUE,
  inserted_at TIMESTAMP,
  updated_at TIMESTAMP
);

CREATE INDEX products_user_id_index ON products(user_id);
CREATE INDEX products_category_index ON products(category);
CREATE INDEX products_expires_at_index ON products(expires_at);
```

### Chat Tables
```sql
-- Messages between customers and vendors
CREATE TABLE chat_messages (
  id BIGSERIAL PRIMARY KEY,
  product_id BIGINT REFERENCES products(id),
  user_id BIGINT REFERENCES users(id), -- NULL for guest messages
  content TEXT NOT NULL,
  sender_name VARCHAR(255),  -- Guest name when user_id is NULL
  sender_email VARCHAR(255), -- Guest email (optional)
  is_vendor_reply BOOLEAN DEFAULT FALSE,
  inserted_at TIMESTAMP,
  updated_at TIMESTAMP
);

-- Conversation management per product
CREATE TABLE conversations (
  id BIGSERIAL PRIMARY KEY,
  product_id BIGINT REFERENCES products(id) UNIQUE,
  status VARCHAR(20) DEFAULT 'open', -- 'open' or 'resolved'
  resolved_at TIMESTAMP,
  resolved_by_user_id BIGINT REFERENCES users(id),
  inserted_at TIMESTAMP,
  updated_at TIMESTAMP
);

-- Read tracking for notifications
CREATE TABLE message_reads (
  id BIGSERIAL PRIMARY KEY,
  message_id BIGINT REFERENCES chat_messages(id),
  user_id BIGINT REFERENCES users(id),
  read_at TIMESTAMP,
  inserted_at TIMESTAMP
);

CREATE INDEX chat_messages_product_id_index ON chat_messages(product_id);
CREATE INDEX conversations_product_id_index ON conversations(product_id);
CREATE INDEX message_reads_user_id_index ON message_reads(user_id);
```

### User Tokens Table
```sql
CREATE TABLE users_tokens (
  id BIGSERIAL PRIMARY KEY,
  user_id BIGINT REFERENCES users(id) ON DELETE CASCADE,
  token BYTEA NOT NULL,
  context VARCHAR(255) NOT NULL,
  sent_to VARCHAR(255),
  authenticated_at TIMESTAMP,
  inserted_at TIMESTAMP
);

CREATE UNIQUE INDEX users_tokens_context_token_index ON users_tokens(context, token);
CREATE INDEX users_tokens_user_id_index ON users_tokens(user_id);
```

## Authentication System

### Magic Link Authentication

The application uses passwordless authentication via magic links:

1. **Login Flow**:
   ```elixir
   # User enters email
   # System generates secure token
   token = :crypto.strong_rand_bytes(32)
   
   # Token is hashed and stored
   hashed_token = :crypto.hash(:sha256, token)
   
   # Email sent with magic link
   url = "https://app.com/users/log-in/#{Base.url_encode64(token)}"
   ```

2. **Token Validation**:
   - Tokens expire after 1 hour
   - One-time use only
   - Secure random generation
   - SHA256 hashing for storage

3. **Session Management**:
   - Phoenix token-based sessions
   - Remember me functionality
   - Secure cookie storage

### Implementation Details

```elixir
# lib/makanan_segar/accounts.ex
def deliver_login_instructions(user, url_fun) do
  {encoded_token, user_token} = UserToken.build_email_token(user, "login")
  Repo.insert!(user_token)
  UserNotifier.deliver_login_instructions(user, url_fun.(encoded_token))
end

def login_user_by_magic_link(token) do
  with {:ok, query} <- UserToken.verify_email_token_query(token, "login"),
       %User{} = user <- Repo.one(query),
       :ok <- confirm_user_if_needed(user),
       :ok <- mark_token_as_used(query) do
    {:ok, {user, clean_expired_tokens(user)}}
  else
    _ -> :error
  end
end
```

## User Roles & Permissions

### Role Types

1. **Guest Users**
   - Browse products
   - **Chat with vendors about products** (no login required)
   - View vendor profiles
   - Must login to purchase

2. **Registered Users**
   - All guest permissions
   - Make purchases
   - Manage profile
   - View order history

3. **Vendors** (`is_vendor: true`)
   - All registered user permissions
   - Access vendor dashboard
   - Manage products (CRUD)
   - View sales analytics
   - Customize business profile

4. **Administrators** (`is_admin: true`)
   - Full platform access
   - User management
   - Vendor approval
   - Content moderation
   - Platform analytics

### Authorization Implementation

```elixir
# lib/makanan_segar_web/user_auth_hooks.ex
defmodule MakananSegarWeb.UserAuthHooks do
  def on_mount(:ensure_authenticated, _params, session, socket) do
    socket = mount_current_user(socket, session)
    
    if socket.assigns.current_user do
      {:cont, socket}
    else
      {:halt, redirect(socket, to: ~p"/users/log-in")}
    end
  end

  def on_mount(:require_vendor_user, _params, session, socket) do
    socket = mount_current_user(socket, session)
    
    if socket.assigns.current_user && socket.assigns.current_user.is_vendor do
      {:cont, socket}
    else
      {:halt, redirect(socket, to: ~p"/")}
      |> put_flash(:error, "You must be a vendor to access this page.")}
    end
  end
end
```

## Key Modules

### Accounts Context

```elixir
# lib/makanan_segar/accounts.ex
- register_user/1          # User registration
- deliver_login_instructions/2  # Send magic link
- login_user_by_magic_link/1   # Authenticate via token
- update_user_email/2      # Update email with confirmation
- update_user_profile/2    # Update profile information
- update_user_roles/2      # Admin-only role management
```

### Chat Context

```elixir
# lib/makanan_segar/chat.ex
- list_product_messages/1       # Get all messages for a product
- create_customer_message/2     # Create guest/customer message
- create_vendor_reply/3         # Create vendor response
- subscribe_to_product_chat/1   # Subscribe to real-time updates
- get_vendor_unread_counts/1    # Get notification badge counts
- mark_conversation_resolved/2  # Mark conversation as resolved
- reopen_conversation/2         # Reopen resolved conversation
- get_conversation_status/1     # Get conversation status

# Message utilities
- Message.display_sender_name/1 # Display name (guest or user)
- Message.is_from_vendor?/1     # Check if vendor message
- Message.is_from_customer?/1   # Check if customer message
```

### Products Context

```elixir
# lib/makanan_segar/products.ex
- list_products/1          # List vendor's products
- list_public_products/0   # List all active products
- get_product!/2           # Get product with scope validation
- create_product/2         # Create new product
- update_product/3         # Update existing product
- delete_product/2         # Delete product
- expired?/1              # Check if product expired
- expiring_soon?/1        # Check if expiring within 24h
```

### Background Workers

```elixir
# lib/makanan_segar/workers/product_expiry_worker.ex
- Scheduled job to mark expired products as inactive
- Runs daily at midnight Malaysia time
- Sends notifications to vendors about expiring products
```

## API Endpoints & Routes

### Public Routes
```elixir
GET  /                      # Home page with product listing & chat
GET  /products/:id          # Product details with chat
GET  /vendors               # List all vendors
GET  /vendors/:id           # Vendor profile

# Real-time chat (via LiveView events)
# - view_product (opens chat modal)
# - send_chat_message (guest messages)
# - Guest messages require: content, sender_name
```

### Authentication Routes
```elixir
GET  /users/register        # Registration page
POST /users/register        # Create account
GET  /users/log-in          # Login page
POST /users/log-in          # Send magic link
GET  /users/log-in/:token   # Validate magic link
DELETE /users/log-out       # Logout
```

### User Routes (Authenticated)
```elixir
GET  /users/settings        # User settings
PUT  /users/settings        # Update profile/email
GET  /users/settings/confirm-email/:token  # Confirm email change
```

### Vendor Routes
```elixir
GET  /vendor                # Vendor dashboard
GET  /vendor/profile        # Edit business profile
GET  /vendor/products       # Manage products
GET  /vendor/products/new   # New product form
POST /vendor/products       # Create product
GET  /vendor/products/:id   # View product
GET  /vendor/products/:id/edit  # Edit product form
PUT  /vendor/products/:id   # Update product
DELETE /vendor/products/:id # Delete product
```

### Admin Routes
```elixir
GET  /admin                 # Admin dashboard
GET  /admin/users           # User management
GET  /admin/users/:id       # User details
PUT  /admin/users/:id/roles # Update user roles
```

## LiveView Components

### Public LiveViews
- `HomeLive` - Main marketplace with product grid and **guest chat**
- `ProductShow` - Product details page with **guest chat**
- `VendorIndex` - Vendor directory
- `VendorShow` - Vendor profile and products

### Chat Components
- `ProductChatComponent` - Real-time chat interface
  - Supports both authenticated users and guests
  - Guest form: name + message content
  - Vendor form: message content only
  - Real-time message updates via PubSub
  - Message history and scrolling

### Vendor LiveViews
- `DashboardLive` - Vendor analytics dashboard with **chat notifications**
- `ProfileLive` - Business profile management
- `ProductLive.Index` - Product management with **chat indicators**
- `ProductLive.Form` - Create/edit products
- `ProductLive.Show` - Product details for vendor with **chat management**

### Admin LiveViews
- `DashboardLive` - Platform statistics
- `UserManagementLive` - User administration

### Shared Components
```elixir
# lib/makanan_segar_web/components/core_components.ex
- modal/1          # Modal dialogs
- button/1         # Consistent button styling
- input/1          # Form inputs with error handling
- label/1          # Form labels
- error/1          # Error messages
- header/1         # Page headers
- table/1          # Data tables
- list/1           # Styled lists
```

## Background Jobs

### Oban Configuration
```elixir
config :makanan_segar, Oban,
  repo: MakananSegar.Repo,
  plugins: [
    Oban.Plugins.Pruner,
    {Oban.Plugins.Cron,
     crontab: [
       {"0 0 * * *", MakananSegar.Workers.ProductExpiryWorker}
     ]}
  ],
  queues: [default: 10]
```

### Product Expiry Worker
- Runs daily at midnight
- Marks expired products as inactive
- Schedules individual product cleanup jobs
- Notifies vendors of expiring products

## Testing

### Test Configuration
```elixir
# config/test.exs
config :makanan_segar, Oban,
  testing: :manual,  # Prevent background jobs in tests
  queues: false,
  plugins: false
```

### Running Tests
```bash
# Run all tests
mix test

# Run specific test file
mix test test/makanan_segar/products_test.exs

# Run with coverage
mix test --cover
```

### Test Structure
- Unit tests for contexts (Accounts, Products, Chat)
- Controller tests for traditional endpoints
- LiveView tests for interactive features
- Integration tests for workflows
- Factory/Fixture modules for test data

### Testing Chat Functionality

#### Guest Chat Testing
```elixir
# Test guest message creation
test "guest can send message to vendor" do
  product = insert(:product)
  
  message_attrs = %{
    "content" => "Is this product fresh?",
    "sender_name" => "John Guest",
    "sender_email" => "john@example.com"
  }
  
  {:ok, message} = Chat.create_customer_message(product.id, message_attrs)
  
  assert message.content == "Is this product fresh?"
  assert message.sender_name == "John Guest"
  assert message.is_vendor_reply == false
  assert message.user_id == nil  # Guest message
end

# Test vendor notification system
test "vendor receives notification for guest message" do
  vendor = insert(:user, is_vendor: true)
  product = insert(:product, user: vendor)
  
  Chat.create_customer_message(product.id, %{
    "content" => "Test message",
    "sender_name" => "Guest User"
  })
  
  unread_counts = Chat.get_vendor_unread_counts_by_product_open_only(vendor.id)
  assert unread_counts[product.id] == 1
end
```

#### LiveView Chat Testing
```elixir
# Test chat modal opening
test "guest can open chat modal for product", %{conn: conn} do
  product = insert(:product)
  
  {:ok, view, _html} = live(conn, ~p"/")
  
  # Click product to open modal
  view |> element("[phx-click='view_product'][phx-value-id='#{product.id}']") |> render_click()
  
  # Modal should be open with chat interface
  assert has_element?(view, "#product-modal")
  assert has_element?(view, "[name='sender_name']")  # Guest name field
  assert has_element?(view, "[name='content']")      # Message content
end

# Test guest message sending
test "guest can send message through modal", %{conn: conn} do
  product = insert(:product)
  
  {:ok, view, _html} = live(conn, ~p"/")
  
  # Open modal and send message
  view |> element("[phx-click='view_product'][phx-value-id='#{product.id}']") |> render_click()
  
  view
  |> form("#chat-form", %{
    "sender_name" => "Test Guest",
    "content" => "Is this available?"
  })
  |> render_submit()
  
  # Check message was created
  messages = Chat.list_product_messages(product.id)
  assert length(messages) == 1
  assert hd(messages).content == "Is this available?"
end
```

#### Integration Testing
```elixir
# Test complete guest-to-vendor flow
test "complete guest chat workflow" do
  vendor = insert(:user, is_vendor: true)
  product = insert(:product, user: vendor)
  
  # 1. Guest sends message
  {:ok, guest_message} = Chat.create_customer_message(product.id, %{
    "content" => "Product inquiry",
    "sender_name" => "Guest Customer"
  })
  
  # 2. Conversation created automatically
  conversation = Chat.get_conversation_by_product(product.id)
  assert conversation.status == "open"
  
  # 3. Vendor receives notification
  unread_counts = Chat.get_vendor_unread_counts_by_product_open_only(vendor.id)
  assert unread_counts[product.id] == 1
  
  # 4. Vendor replies
  {:ok, vendor_reply} = Chat.create_vendor_reply(
    product.id, 
    vendor.id, 
    "Thank you for your inquiry!"
  )
  
  # 5. Messages are ordered correctly
  messages = Chat.list_product_messages(product.id)
  assert length(messages) == 2
  assert hd(messages).id == guest_message.id
  assert List.last(messages).id == vendor_reply.id
  
  # 6. Vendor can mark as resolved
  {:ok, _} = Chat.mark_conversation_resolved(product.id, vendor.id)
  updated_conversation = Chat.get_conversation_by_product(product.id)
  assert updated_conversation.status == "resolved"
end
```

### Real-time Performance Considerations

#### **Connection Management**
- LiveView connections auto-reconnect on network issues
- PubSub scales across multiple server nodes
- Graceful degradation for offline users
- Message queuing for temporary disconnections

#### **Scalability Features**
- Channel-based broadcasting reduces unnecessary updates
- Product-specific subscriptions minimize bandwidth
- Unread count caching for performance
- Lazy loading of chat history

#### **Development Tools**
```bash
# View active PubSub subscribers (development)
iex> Registry.count(Phoenix.PubSub.PG2)

# Monitor message broadcasting
iex> :sys.trace(MakananSegar.PubSub, true)

# Test real-time features
mix test test/makanan_segar_web/live/home_live_test.exs
```

## Deployment

### Production Checklist

1. **Environment Setup**
   ```bash
   export MIX_ENV=prod
   export PHX_HOST=your-domain.com
   export DATABASE_URL=your-database-url
   export SECRET_KEY_BASE=$(mix phx.gen.secret)
   ```

2. **Build Release**
   ```bash
   mix deps.get --only prod
   MIX_ENV=prod mix compile
   MIX_ENV=prod mix assets.deploy
   MIX_ENV=prod mix release
   ```

3. **Database Migration**
   ```bash
   _build/prod/rel/makanan_segar/bin/makanan_segar eval "MakananSegar.Release.migrate"
   ```

4. **Start Application**
   ```bash
   _build/prod/rel/makanan_segar/bin/makanan_segar start
   ```

### Production Considerations

- Configure production email adapter (SendGrid, AWS SES, etc.)
- Set up SSL/TLS certificates
- Configure CDN for static assets
- Set up monitoring (AppSignal, New Relic, etc.)
- Configure log aggregation
- Set up database backups
- Configure rate limiting
- Set up error tracking (Sentry, Rollbar, etc.)

### Scaling Considerations

- Database connection pooling
- Redis for caching and PubSub
- Horizontal scaling with libcluster
- CDN for asset delivery
- Database read replicas
- Background job queuing optimization

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.
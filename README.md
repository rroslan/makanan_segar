# MakananSegar - Fresh Food Marketplace

MakananSegar is a Phoenix LiveView application that connects local fresh food vendors with customers in Malaysia. The platform enables vendors to list their fresh products (fish, vegetables, fruits) and customers to discover and purchase fresh, locally-sourced food.

## Table of Contents

- [Features](#features)
- [Technical Stack](#technical-stack)
- [Architecture Overview](#architecture-overview)
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
- View product details, expiry dates, and vendor information
- Filter products by category (fish, vegetables, fruits)
- View vendor profiles and their product listings
- Secure magic link authentication for purchases

### For Vendors
- Vendor dashboard with sales analytics
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

1. **Context-based Architecture**: Business logic is organized into contexts (Accounts, Products)
2. **LiveView for Real-time UI**: Interactive features without JavaScript
3. **Component-based UI**: Reusable function components for consistent UI
4. **Role-based Access Control**: Middleware-based authentication and authorization
5. **Event-driven Updates**: PubSub for real-time synchronization

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
GET  /                      # Home page with product listing
GET  /products              # Browse all products
GET  /products/:id          # Product details
GET  /vendors               # List all vendors
GET  /vendors/:id           # Vendor profile
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
- `HomeLive` - Main marketplace with product grid
- `ProductIndex` - Product browsing with filters
- `ProductShow` - Product details page
- `VendorIndex` - Vendor directory
- `VendorShow` - Vendor profile and products

### Vendor LiveViews
- `DashboardLive` - Vendor analytics dashboard
- `ProfileLive` - Business profile management
- `ProductLive.Index` - Product management
- `ProductLive.Form` - Create/edit products
- `ProductLive.Show` - Product details for vendor

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
- Unit tests for contexts (Accounts, Products)
- Controller tests for traditional endpoints
- LiveView tests for interactive features
- Integration tests for workflows
- Factory/Fixture modules for test data

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
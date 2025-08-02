# 🛠️ Setting Up Named Roles and Authorization in Phoenix

This tutorial helps you upgrade from boolean-based roles (like `is_admin`) to a more scalable system using a `roles` table and a `user_roles` join table in your Phoenix app. It’s designed for beginners and follows best practices for flexible, centralized authorization.

---

## 🧠 Overview

**What you'll build:**

- Named roles like `admin`, `vendor`, `cashier`
- Users can have **multiple roles**
- Centralized `can?/2` permission checks
- Optional support for scoped permissions in the future

---

## 1️⃣ Generate Roles and UserRoles Tables

### Create the `roles` table

```sh
mix phx.gen.schema Accounts.Role roles name:string:unique
```

Migration:

```elixir
def change do
  create table(:roles) do
    add :name, :string, null: false
    timestamps()
  end

  create unique_index(:roles, [:name])
end
```

### Create the join table `user_roles`

```sh
mix phx.gen.schema Accounts.UserRole user_roles user_id:references:users role_id:references:roles
```

Migration:

```elixir
def change do
  create table(:user_roles) do
    add :user_id, references(:users, on_delete: :delete_all), null: false
    add :role_id, references(:roles, on_delete: :delete_all), null: false
    timestamps()
  end

  create unique_index(:user_roles, [:user_id, :role_id])
end
```

---

## 2️⃣ Update Your Schemas

### `user.ex`

```elixir
has_many :user_roles, MakananSegar.Accounts.UserRole
has_many :roles, through: [:user_roles, :role]
```

### `role.ex`

```elixir
schema "roles" do
  field :name, :string
  has_many :user_roles, MakananSegar.Accounts.UserRole
  has_many :users, through: [:user_roles, :user]
  timestamps()
end
```

### `user_role.ex`

```elixir
schema "user_roles" do
  belongs_to :user, MakananSegar.Accounts.User
  belongs_to :role, MakananSegar.Accounts.Role
  timestamps()
end
```

---

## 3️⃣ Seed Roles in `priv/repo/seeds.exs`

```elixir
alias MakananSegar.Repo
alias MakananSegar.Accounts.Role

["admin", "vendor", "cashier"]
|> Enum.each(fn name ->
  Repo.insert!(%Role{name: name})
end)
```

Then run:

```sh
mix run priv/repo/seeds.exs
```

---

## 4️⃣ Assign Roles to Users

### Add to `accounts.ex`

```elixir
def assign_role_to_user(user, role_name) do
  role = Repo.get_by!(Role, name: role_name)
  %UserRole{}
  |> UserRole.changeset(%{user_id: user.id, role_id: role.id})
  |> Repo.insert()
end
```

---

## 5️⃣ Add Authorization Module

### `lib/makanan_segar/accounts/authorization.ex`

```elixir
defmodule MakananSegar.Accounts.Authorization do
  def has_role?(%{roles: roles}, role_name) when is_binary(role_name) do
    Enum.any?(roles, fn role -> role.name == role_name end)
  end

  def can?(user, :manage_products), do: has_role?(user, "vendor")
  def can?(user, :manage_users), do: has_role?(user, "admin")
  def can?(user, :handle_cash), do: has_role?(user, "cashier")
  def can?(_, _), do: false
end
```

---

## 6️⃣ Protect LiveViews with `on_mount`

### `user_auth_hooks.ex`

```elixir
def on_mount(:require_role, role_name, _params, _session, socket) do
  user = socket.assigns.current_user

  if Authorization.has_role?(user, role_name) do
    {:cont, socket}
  else
    {:halt,
     socket
     |> Phoenix.LiveView.put_flash(:error, "You don't have access.")
     |> Phoenix.LiveView.redirect(to: "/")}
  end
end
```

### Router usage:

```elixir
live_session :admin_only, on_mount: [
  {MakananSegarWeb.UserAuthHooks, :ensure_authenticated},
  {MakananSegarWeb.UserAuthHooks, {:require_role, "admin"}}
] do
  live "/admin/users", AdminUserLive
end
```

---

## ✅ Done! Benefits

| Feature            | Benefit                                     |
| ------------------ | ------------------------------------------- |
| Named roles        | Scalable & readable                         |
| Multiple roles     | Users can wear multiple hats                |
| Centralized can?/2 | Declarative, testable permission checks     |
| Scoped-ready       | Easy to extend to `can?(user, action, res)` |

---

Would you like to migrate existing users (`is_admin`, `is_vendor`) to this structure? Let me know!


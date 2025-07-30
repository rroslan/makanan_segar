defmodule MakananSegarWeb.Layouts do
  @moduledoc """
  This module holds layouts and related functionality
  used by your application.
  """
  use MakananSegarWeb, :html

  # Embed all files in layouts/* within this module.
  # The default root.html.heex file contains the HTML
  # skeleton of your application, namely HTML headers
  # and other static content.
  embed_templates "layouts/*"

  @doc """
  Renders your app layout.

  This function is typically invoked from every template,
  and it often contains your application menu, sidebar,
  or similar.

  ## Examples

      <Layouts.app flash={@flash}>
        <h1>Content</h1>
      </Layouts.app>

  """
  attr :flash, :map, required: true, doc: "the map of flash messages"

  attr :current_scope, :map,
    default: nil,
    doc: "the current [scope](https://hexdocs.pm/phoenix/scopes.html)"

  slot :inner_block, required: true

  def app(assigns) do
    ~H"""
    <!-- Mobile-first responsive navigation -->
    <div class="navbar bg-base-100 shadow-sm">
      <div class="navbar-start">
        <div class="dropdown">
          <div tabindex="0" role="button" class="btn btn-ghost lg:hidden">
            <svg
              xmlns="http://www.w3.org/2000/svg"
              class="h-5 w-5"
              fill="none"
              viewBox="0 0 24 24"
              stroke="currentColor"
            >
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M4 6h16M4 12h8m-8 6h16"
              />
            </svg>
          </div>
          <!-- Mobile menu -->
          <ul
            tabindex="0"
            class="menu menu-sm dropdown-content mt-3 z-[1] p-2 shadow bg-base-100 rounded-box w-52"
          >
            <%= if @current_scope && @current_scope.user do %>
              <%= if @current_scope.user.is_admin do %>
                <li><.link navigate={~p"/admin"}>⚙️ Admin Dashboard</.link></li>
              <% end %>
              <%= if @current_scope.user.is_vendor do %>
                <li><.link navigate={~p"/vendor"}>📊 Vendor Dashboard</.link></li>
              <% end %>
              <li><.link navigate={~p"/users/settings"}>⚙️ Settings</.link></li>
              <li>
                <.form for={%{}} action={~p"/users/log-out"} method="delete" class="w-full">
                  <button
                    type="submit"
                    class="w-full text-left px-4 py-2 hover:bg-base-200 rounded-lg transition-colors"
                    onclick="this.disabled=true; this.innerHTML='🚪 Logging out...'; this.form.submit();"
                  >
                    🚪 Log out
                  </button>
                </.form>
              </li>
            <% else %>
              <li><.link navigate={~p"/users/log-in"}>🔑 Log in</.link></li>
              <li><.link navigate={~p"/users/register"}>👤 Register</.link></li>
            <% end %>
          </ul>
        </div>
        <!-- Logo -->
        <.link navigate={~p"/"} class="btn btn-ghost text-xl">
          <span class="text-2xl mr-2">🥬</span>
          <span class="hidden sm:inline">MakananSegar</span>
          <span class="sm:hidden">MS</span>
        </.link>
      </div>
      
    <!-- Desktop navigation -->
      <div class="navbar-center hidden lg:flex">
        <!-- Navigation links removed - home page shows all products -->
      </div>

      <div class="navbar-end">
        <!-- Dashboard buttons for mobile -->
        <%= if @current_scope && @current_scope.user do %>
          <div class="flex items-center gap-2">
            <%= if @current_scope.user.is_admin do %>
              <.link navigate={~p"/admin"} class="btn btn-primary btn-sm hidden sm:flex">
                Admin
              </.link>
            <% end %>
            <%= if @current_scope.user.is_vendor do %>
              <.link navigate={~p"/vendor"} class="btn btn-success btn-sm hidden sm:flex">
                Vendor
              </.link>
            <% end %>
            
    <!-- User avatar dropdown -->
            <div class="dropdown dropdown-end">
              <div tabindex="0" role="button" class="btn btn-ghost btn-circle avatar">
                <div class="w-10 rounded-full">
                  <%= if @current_scope.user.profile_image do %>
                    <img
                      alt={@current_scope.user.name || @current_scope.user.email}
                      src={@current_scope.user.profile_image}
                    />
                  <% else %>
                    <div class="w-10 h-10 rounded-full bg-primary text-primary-content flex items-center justify-center font-semibold">
                      {get_user_initials(@current_scope.user)}
                    </div>
                  <% end %>
                </div>
              </div>
              <ul
                tabindex="0"
                class="menu menu-sm dropdown-content mt-3 z-[1] p-2 shadow bg-base-100 rounded-box w-52"
              >
                <li class="menu-title">
                  <span class="text-xs">{@current_scope.user.name || "User"}</span>
                  <span class="text-xs opacity-60">{@current_scope.user.email}</span>
                </li>
                <li><.link navigate={~p"/users/settings"}>⚙️ Settings</.link></li>
                <li>
                  <.form for={%{}} action={~p"/users/log-out"} method="delete" class="w-full">
                    <button
                      type="submit"
                      class="w-full text-left px-4 py-2 hover:bg-base-200 rounded-lg transition-colors"
                      onclick="this.disabled=true; this.innerHTML='🚪 Logging out...'; this.form.submit();"
                    >
                      🚪 Log out
                    </button>
                  </.form>
                </li>
              </ul>
            </div>
          </div>
        <% else %>
          <!-- Not logged in -->
          <div class="flex items-center gap-2">
            <.link navigate={~p"/users/log-in"} class="btn btn-ghost btn-sm">
              Log in
            </.link>
            <.link navigate={~p"/users/register"} class="btn btn-primary btn-sm">
              Register
            </.link>
          </div>
        <% end %>
        
    <!-- Theme toggle -->
        <div class="ml-2">
          <.theme_toggle />
        </div>
      </div>
    </div>

    <main class="min-h-screen">
      {render_slot(@inner_block)}
    </main>

    <.flash_group flash={@flash} />
    """
  end

  defp get_user_initials(user) do
    cond do
      user.name && String.length(user.name) > 0 ->
        user.name
        |> String.split()
        |> Enum.take(2)
        |> Enum.map(&String.first/1)
        |> Enum.join()
        |> String.upcase()

      user.email ->
        String.first(user.email) |> String.upcase()

      true ->
        "U"
    end
  end

  @doc """
  Shows the flash group with standard titles and content.

  ## Examples

      <.flash_group flash={@flash} />
  """
  attr :flash, :map, required: true, doc: "the map of flash messages"
  attr :id, :string, default: "flash-group", doc: "the optional id of flash container"

  def flash_group(assigns) do
    ~H"""
    <div id={@id} aria-live="polite">
      <.flash kind={:info} flash={@flash} />
      <.flash kind={:error} flash={@flash} />

      <.flash
        id="client-error"
        kind={:error}
        title={gettext("We can't find the internet")}
        phx-disconnected={show(".phx-client-error #client-error") |> JS.remove_attribute("hidden")}
        phx-connected={hide("#client-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
      </.flash>

      <.flash
        id="server-error"
        kind={:error}
        title={gettext("Something went wrong!")}
        phx-disconnected={show(".phx-server-error #server-error") |> JS.remove_attribute("hidden")}
        phx-connected={hide("#server-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
      </.flash>
    </div>
    """
  end

  @doc """
  Provides dark vs light theme toggle based on themes defined in app.css.

  See <head> in root.html.heex which applies the theme before page load.
  """
  def theme_toggle(assigns) do
    ~H"""
    <div class="card relative flex flex-row items-center border-2 border-base-300 bg-base-300 rounded-full">
      <div class="absolute w-1/3 h-full rounded-full border-1 border-base-200 bg-base-100 brightness-200 left-0 [[data-theme=light]_&]:left-1/3 [[data-theme=dark]_&]:left-2/3 transition-[left]" />

      <button
        phx-click={JS.dispatch("phx:set-theme", detail: %{theme: "system"})}
        class="flex p-2 cursor-pointer w-1/3"
      >
        <.icon name="hero-computer-desktop-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>

      <button
        phx-click={JS.dispatch("phx:set-theme", detail: %{theme: "light"})}
        class="flex p-2 cursor-pointer w-1/3"
      >
        <.icon name="hero-sun-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>

      <button
        phx-click={JS.dispatch("phx:set-theme", detail: %{theme: "dark"})}
        class="flex p-2 cursor-pointer w-1/3"
      >
        <.icon name="hero-moon-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>
    </div>
    """
  end
end

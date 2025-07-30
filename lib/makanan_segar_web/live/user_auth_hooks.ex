defmodule MakananSegarWeb.UserAuthHooks do
  @moduledoc """
  Authentication hooks for LiveViews.

  This module provides hooks that can be used with `on_mount` to ensure
  that LiveViews have access to the current user and scope information.
  """

  import Phoenix.Component
  import Phoenix.LiveView

  alias MakananSegar.Accounts

  def on_mount(:default, _params, session, socket) do
    socket = assign_current_scope(socket, session)
    {:cont, socket}
  end

  def on_mount(:require_authenticated_user, _params, session, socket) do
    socket = assign_current_scope(socket, session)

    if socket.assigns.current_scope && socket.assigns.current_scope.user do
      {:cont, socket}
    else
      {:halt, redirect(socket, to: "/users/log-in")}
    end
  end

  def on_mount(:require_admin_user, _params, session, socket) do
    socket = assign_current_scope(socket, session)

    if socket.assigns.current_scope &&
         socket.assigns.current_scope.user &&
         MakananSegar.Accounts.User.admin?(socket.assigns.current_scope.user) do
      {:cont, socket}
    else
      {:halt, redirect(socket, to: "/")}
    end
  end

  def on_mount(:require_vendor_user, _params, session, socket) do
    socket = assign_current_scope(socket, session)

    if socket.assigns.current_scope &&
         socket.assigns.current_scope.user &&
         MakananSegar.Accounts.User.vendor?(socket.assigns.current_scope.user) do
      {:cont, socket}
    else
      {:halt, redirect(socket, to: "/")}
    end
  end

  def on_mount(:require_admin_or_vendor_user, _params, session, socket) do
    socket = assign_current_scope(socket, session)

    if socket.assigns.current_scope && socket.assigns.current_scope.user do
      user = socket.assigns.current_scope.user

      if MakananSegar.Accounts.User.admin?(user) || MakananSegar.Accounts.User.vendor?(user) do
        {:cont, socket}
      else
        {:halt, redirect(socket, to: "/")}
      end
    else
      {:halt, redirect(socket, to: "/users/log-in")}
    end
  end

  def on_mount(:require_complete_vendor_profile, _params, session, socket) do
    socket = assign_current_scope(socket, session)

    if socket.assigns.current_scope && socket.assigns.current_scope.user do
      user = socket.assigns.current_scope.user

      cond do
        !MakananSegar.Accounts.User.vendor?(user) ->
          {:halt, redirect(socket, to: "/")}

        !profile_complete?(user) ->
          socket =
            socket
            |> put_flash(:error, "Please complete your vendor profile before adding products.")
            |> redirect(to: "/vendor/profile")

          {:halt, socket}

        true ->
          {:cont, socket}
      end
    else
      {:halt, redirect(socket, to: "/users/log-in")}
    end
  end

  defp profile_complete?(user) do
    user.business_name && user.phone && user.address
  end

  defp assign_current_scope(socket, session) do
    case session do
      %{"user_token" => user_token} when is_binary(user_token) ->
        case Accounts.get_user_by_session_token(user_token) do
          {user, _token_inserted_at} ->
            current_scope = Accounts.Scope.for_user(user)
            assign(socket, :current_scope, current_scope)

          nil ->
            assign(socket, :current_scope, nil)
        end

      _ ->
        assign(socket, :current_scope, nil)
    end
  end
end

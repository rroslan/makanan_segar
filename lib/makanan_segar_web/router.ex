defmodule MakananSegarWeb.Router do
  use MakananSegarWeb, :router

  import MakananSegarWeb.UserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {MakananSegarWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_scope_for_user
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", MakananSegarWeb do
    pipe_through :browser

    live "/", PublicLive.HomeLive, :index
  end

  ## Admin routes
  scope "/admin", MakananSegarWeb.Admin, as: :admin do
    pipe_through [:browser, :require_authenticated_user, :require_admin_user]

    live "/", DashboardLive, :index
    live "/users", UserManagementLive, :index
    live "/users/:id", UserManagementLive, :show
  end

  ## Vendor routes
  scope "/vendor", MakananSegarWeb.Vendor, as: :vendor do
    pipe_through [:browser, :require_authenticated_user, :require_vendor_user]

    live "/", DashboardLive, :index
    live "/profile", ProfileLive, :edit
    live "/products", ProductLive.Index, :index
    live "/products/new", ProductLive.Form, :new
    live "/products/:id/edit", ProductLive.Form, :edit
    live "/products/:id", ProductLive.Show, :show
    live "/products/:id/show/edit", ProductLive.Show, :edit
  end

  # Other scopes may use custom stacks.
  # scope "/api", MakananSegarWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:makanan_segar, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: MakananSegarWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  ## Authentication routes

  scope "/", MakananSegarWeb do
    pipe_through [:browser, :redirect_if_user_is_authenticated]

    get "/users/register", UserRegistrationController, :new
    post "/users/register", UserRegistrationController, :create
  end

  scope "/", MakananSegarWeb do
    pipe_through [:browser, :require_authenticated_user]

    get "/users/settings", UserSettingsController, :edit
    put "/users/settings", UserSettingsController, :update
    get "/users/settings/confirm-email/:token", UserSettingsController, :confirm_email
  end

  scope "/", MakananSegarWeb do
    pipe_through [:browser]

    get "/users/log-in", UserSessionController, :new
    get "/users/log-in/:token", UserSessionController, :confirm
    post "/users/log-in", UserSessionController, :create
    delete "/users/log-out", UserSessionController, :delete
  end

  ## Public routes for browsing products
  scope "/", MakananSegarWeb do
    pipe_through :browser


    live "/products/:id", PublicLive.ProductShow, :show
    live "/vendors", PublicLive.VendorIndex, :index
    live "/vendors/:id", PublicLive.VendorShow, :show
  end
end

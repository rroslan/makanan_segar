import Config

# config/runtime.exs is executed for all environments, including
# during releases. It is executed after compilation and before the
# system starts, so it is typically used to load production configuration
# and secrets from environment variables or elsewhere. Do not define
# any compile-time configuration in here, as it won't be applied.
# The block below contains prod specific runtime configuration.

# ## Using releases
#
# If you use `mix release`, you need to explicitly enable the server
# by passing the PHX_SERVER=true when you start it:
#
#     PHX_SERVER=true bin/makanan_segar start
#
# Alternatively, you can use `mix phx.gen.release` to generate a `bin/server`
# script that automatically sets the env var above.
if System.get_env("PHX_SERVER") do
  config :makanan_segar, MakananSegarWeb.Endpoint, server: true
end

if config_env() == :prod do
  database_url =
    System.fetch_env!("DATABASE_URL")

  config :makanan_segar, MakananSegar.Mailer,
    adapter: Resend.Swoosh.Adapter,
    api_key: System.fetch_env!("RESEND_API_KEY"),
    from: {"Makanan Segar", "noreply@applikasi.tech"}

  # The Swoosh API client is configured in `config/prod.exs` to use Req.
  # We remove the line here to avoid overriding it with Finch.
  # config :swoosh, :api_client, Swoosh.ApiClient.Finch
  maybe_ipv6 = if System.get_env("ECTO_IPV6") in ~w(true 1), do: [:inet6], else: []

  config :makanan_segar, MakananSegar.Repo,
    # ssl: true, # Enable this if your database is external
    url: database_url,
    pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10"),
    # A longer timeout is useful for background jobs (Oban) that hold a
    # connection for a while.
    pool_timeout: 3600,
    socket_options: maybe_ipv6

  # The secret key base is used to sign/encrypt cookies and other secrets.
  # A default value is used in config/dev.exs and config/test.exs but you
  # want to use a different value for prod and you most likely don't want
  # to check this value into version control, so we use an environment
  # variable instead.
  secret_key_base =
    System.fetch_env!("SECRET_KEY_BASE")

  host = System.get_env("PHX_HOST") || "applikasi.tech"
  port = String.to_integer(System.get_env("PORT") || "4010")

  config :makanan_segar, :dns_cluster_query, System.get_env("DNS_CLUSTER_QUERY")

  config :makanan_segar, MakananSegarWeb.Endpoint,
    url: [host: host, port: 443, scheme: "https"],
    check_origin: ["https://applikasi.tech", "https://www.applikasi.tech"],
    http: [
      # Since Nginx is handling public traffic, we bind to the loopback
      # address for added security. This prevents direct access to the app.
      ip: {127, 0, 0, 1},
      port: port
    ],
    secret_key_base: secret_key_base

  # Configure upload directory for production
  # IMPORTANT: Set the UPLOADS_DIR env var to a persistent path
  # outside of your release directory, e.g., /var/www/makanan_segar/uploads
  uploads_dir =
    System.get_env("UPLOADS_DIR", "/var/www/makanan_segar/uploads")
  File.mkdir_p!(uploads_dir)

  config :makanan_segar, :uploads_dir, uploads_dir

  # ## SSL Support
  #
  # To get SSL working, you will need to add the `https` key
  # to your endpoint configuration:
  #
  #     config :makanan_segar, MakananSegarWeb.Endpoint,
  #       https: [
  #         ...,
  #         port: 443,
  #         cipher_suite: :strong,
  #         keyfile: System.get_env("SOME_APP_SSL_KEY_PATH"),
  #         certfile: System.get_env("SOME_APP_SSL_CERT_PATH")
  #       ]
  #
  # The `cipher_suite` is set to `:strong` to support only the
  # latest and more secure SSL ciphers. This means old browsers
  # and clients may not be supported. You can set it to
  # `:compatible` for wider support.
  #
  # `:keyfile` and `:certfile` expect an absolute path to the key
  # and cert in disk or a relative path inside priv, for example
  # "priv/ssl/server.key". For all supported SSL configuration
  # options, see https://hexdocs.pm/plug/Plug.SSL.html#configure/1
  #
  # We also recommend setting `force_ssl` in your config/prod.exs,
  # ensuring no data is ever sent via http, always redirecting to https:
  #
  #     config :makanan_segar, MakananSegarWeb.Endpoint,
  #       force_ssl: [hsts: true]
  #
  # Check `Plug.SSL` for all available options in `force_ssl`.

  # ## Configuring the mailer
  #
  # In production you need to configure the mailer to use a different adapter.
  # Here is an example configuration for Mailgun:
  #
  #     config :makanan_segar, MakananSegar.Mailer,
  #       adapter: Swoosh.Adapters.Mailgun,
  #       api_key: System.get_env("MAILGUN_API_KEY"),
  #       domain: System.get_env("MAILGUN_DOMAIN")
  #
  # Most non-SMTP adapters require an API client. Swoosh supports Req, Hackney,
  # and Finch out-of-the-box. This configuration is typically done at
  # compile-time in your config/prod.exs:
  #
  #     config :swoosh, :api_client, Swoosh.ApiClient.Req
  #
  # See https://hexdocs.pm/swoosh/Swoosh.html#module-installation for details.
end
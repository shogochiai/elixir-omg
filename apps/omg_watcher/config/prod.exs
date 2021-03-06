use Mix.Config

# For production, we often load configuration from external
# sources, such as your system environment. For this reason,
# you won't find the :http configuration below, but set inside
# OMG.Watcher.Web.Endpoint.init/2 when load_from_system_env is
# true. Any dynamic configuration should be done there.
#
# Don't forget to configure the url host to something meaningful,
# Phoenix uses this information when generating URLs.
#
# Finally, we also include the path to a cache manifest
# containing the digested version of static files. This
# manifest is generated by the mix phx.digest task
# which you typically run after static files are built.
config :omg_watcher, OMG.Watcher.Web.Endpoint,
  load_from_system_env: true,
  url: [host: "example.com", port: 80],
  cache_static_manifest: "priv/static/cache_manifest.json"

# Configure your database
config :omg_watcher, OMG.Watcher.DB.Repo,
  adapter: Ecto.Adapters.Postgres,
  # DATABASE_URL format is following `postgres://{user_name}:{password}@{host:port}/{database_name}`
  url: {:system, "DATABASE_URL", "postgres://omisego_dev:omisego_dev@localhost/omisego_prod"}

# ## SSL Support
#
# To get SSL working, you will need to add the `https` key
# to the previous section and set your `:url` port to 443:
#
#     config :omg_watcher, OMG.Watcher.Web.Endpoint,
#       ...
#       url: [host: "example.com", port: 443],
#       https: [:inet6,
#               port: 443,
#               keyfile: System.get_env("SOME_APP_SSL_KEY_PATH"),
#               certfile: System.get_env("SOME_APP_SSL_CERT_PATH")]
#
# Where those two env variables return an absolute path to
# the key and cert in disk or a relative path inside priv,
# for example "priv/ssl/server.key".
#
# We also recommend setting `force_ssl`, ensuring no data is
# ever sent via http, always redirecting to https:
#
#     config :omg_watcher, OMG.Watcher.Web.Endpoint,
#       force_ssl: [hsts: true]
#
# Check `Plug.SSL` for all available options in `force_ssl`.

# ## Using releases
#
# If you are doing OTP releases, you need to instruct Phoenix
# to start the server for all endpoints:
#
#     config :phoenix, :serve_endpoints, true
#
# Alternatively, you can configure exactly which server to
# start per endpoint:
#
#     config :omg_watcher, OMG.Watcher.Web.Endpoint, server: true
#

# Finally import the config/prod.secret.exs
# which should be versioned separately.
try do
  import_config "prod.secret.exs"
rescue
  # for Elixir >= v1.7
  error in Code.LoadError ->
    IO.puts(inspect(error))

  # for Elixir < v1.7
  error in Mix.Config.LoadError ->
    IO.puts(inspect(error))
end

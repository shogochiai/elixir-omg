use Mix.Config

# We need to start OMG.RPC.Web.Endpoint with HTTP server for Performance and Watcher tests to work
# as a drawback lightweight (without HTTP server) controller tests are no longer an option.
config :omg_rpc, OMG.RPC.Web.Endpoint, server: true

# Print only warnings and errors during test
config :logger, level: :warn

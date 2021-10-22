import Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :iasc_elixir_crdt_horde, IascElixirCrdtHordeWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "M0LxW+W4/zA4LaIJHTHJY5ydHHZtct+HlBg+VtQdLZVgjo0Tu52qV8u3EsP7+DAN",
  server: false

# In test we don't send emails.
config :iasc_elixir_crdt_horde, IascElixirCrdtHorde.Mailer,
  adapter: Swoosh.Adapters.Test

# Print only warnings and errors during test
config :logger, level: :warn

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

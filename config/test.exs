import Config

config :filtrex, Filtrex.Repo,
  adapter: Ecto.Adapters.Postgres,
  database: "filtrex_test",
  username: "postgres",
  password: "postgres"

config :logger, level: :info

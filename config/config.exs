import Config

config :filtrex, ecto_repos: [Filtrex.Repo]

if Mix.env() == :test do
  import_config "test.exs"
end

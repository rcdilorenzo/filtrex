defmodule Filtrex.Repo do
  use Ecto.Repo,
    otp_app: :filtrex,
    adapter: Ecto.Adapters.Postgres
end

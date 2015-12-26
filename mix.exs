defmodule Filtrex.Mixfile do
  use Mix.Project

  def project do
    [app: :filtrex,
     version: "0.0.1",
     elixir: "~> 1.1",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     elixirc_paths: elixirc_paths(Mix.env),
     deps: deps,
     name: "Filtrex",
     docs: [main: "Filtrex",
            source_url: "https://github.com/rcdilorenzo/filtrex"]]
  end

  def elixirc_paths(:test), do: ~w(lib test/support)
  def elixirc_paths(_), do: ~w(lib)

  def application do
    [applications: [:logger] ++ applications(Mix.env)]
  end

  def applications(:test), do: [:postgrex, :ecto]
  def applications(_), do: []

  defp deps do
    [
      {:postgrex, ">= 0.0.0", only: :test},
      {:ecto, "~> 1.1", only: :test},
      {:timex, "~> 0.19.5"},
      {:earmark, "~> 0.1", only: :dev},
      {:ex_doc, "~> 0.11", only: :dev},
      {:inch_ex, only: :docs}
    ]
  end
end

defmodule Filtrex.Mixfile do
  use Mix.Project

  def project do
    [app: :filtrex,
     version: "0.3.0-dev",
     elixir: "~> 1.2",
     description: description,
     package: package,
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     elixirc_paths: elixirc_paths(Mix.env),
     deps: deps,
     name: "Filtrex",
     docs: [main: "Filtrex",
            source_url: "https://github.com/rcdilorenzo/filtrex"]]
  end

  defp elixirc_paths(:test), do: ~w(lib test/support)
  defp elixirc_paths(_), do: ~w(lib)

  def application do
    [applications: [:logger, :tzdata] ++ applications(Mix.env)]
  end

  defp applications(:test), do: [:postgrex, :ecto]
  defp applications(_), do: []

  defp description do
    """
    A library for performing and validating complex filters from a client (e.g. smart filters)
    """
  end

  defp deps do
    [
      {:postgrex, ">= 0.0.0", only: :test},
      {:ecto, ">= 1.1.0"},
      {:timex, "~> 2.1.4"},
      {:earmark, "~> 0.1", only: :dev},
      {:ex_doc, "~> 0.11", only: :dev},
      {:inch_ex, ">= 0.0.0", only: [:dev, :docs]},
      {:plug, "~> 1.1.2", only: :test}
    ]
  end

  defp package do
    [
      maintainers: ["Christian Di Lorenzo"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/rcdilorenzo/filtrex",
               "Docs" => "http://rcdilorenzo.github.io/filtrex"}
    ]
  end
end

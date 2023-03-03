defmodule Filtrex.Mixfile do
  use Mix.Project

  def project do
    [
      app: :filtrex,
      version: "0.5.0",
      elixir: "~> 1.13.4",
      description: description(),
      package: package(),
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      elixirc_paths: elixirc_paths(Mix.env()),
      deps: deps(),
      dialyzer: dialyzer(),
      name: "Filtrex",
      docs: [main: "Filtrex", source_url: "https://github.com/rcdilorenzo/filtrex"]
    ]
  end

  defp elixirc_paths(:test), do: ~w(lib test/support)
  defp elixirc_paths(_), do: ~w(lib)

  def application do
    [extra_applications: [:logger, :tzdata] ++ applications(Mix.env())]
  end

  defp applications(:test), do: [:postgrex, :ecto, :ex_machina]
  defp applications(_), do: []

  defp description do
    """
    A library for performing and validating complex filters from a client (e.g. smart filters)
    """
  end

  defp deps do
    [
      {:postgrex, ">= 0.0.0", only: :test},
      {:ecto, "~> 3.0"},
      {:ecto_sql, "~> 3.0"},
      {:timex, "~> 3.1"},
      {:earmark, "~> 0.1", only: :dev},
      {:ex_doc, "~> 0.11", only: :dev},
      {:inch_ex, ">= 0.0.0", only: [:dev, :docs]},
      {:plug, "~> 1.1.2", only: :test},
      {:ex_machina, "~> 0.6.1", only: :test},
      {:mix_test_watch, "~> 0.3", only: :dev, runtime: false},
      {:dialyxir, "~> 1.2.0", only: [:dev], runtime: false}
    ]
  end

  defp package do
    [
      maintainers: ["Christian Di Lorenzo"],
      licenses: ["MIT"],
      links: %{
        "GitHub" => "https://github.com/rcdilorenzo/filtrex",
        "Docs" => "http://rcdilorenzo.github.io/filtrex"
      }
    ]
  end

  defp dialyzer do
    [
      plt_add_deps: :app_tree,
      plt_add_apps: [:ex_unit, :mix],
      plt_file: {:no_warn, "priv/plts/dialyzer.plt"}
    ]
  end
end

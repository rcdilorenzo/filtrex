# Filtrex

Filtrex is an elixir library for parsing and querying with filter data structures. Although it does not direcly require [Ecto](https://github.com/elixir-lang/ecto), it is definitely geared towards using that library. Additionally, it has only been tested using the Postrgres adapter but may work with other Ecto adapters as well. It uses the following query expression and can be validated using `Filtrex.parse/2`.


## Usage

```elixir
config = %{text: %{keys: ~(title comments)}}

{:ok, filter} = Filtrex.parse(config, %{
  filter: %{
    type: "all"                # all | any | none
    conditions: [%{
      column: "title",
      comparator: "contains",  # is, is not, equals, contains, does not contain
      value: "Buy",
      type: "text"
    }]
  }
}
```

The configuration passed into `Filtrex.parse/2` gives the individual condition types more information to validate the filter against and is a required argument. See [this section](http://rcdilorenzo.github.io/filtrex/Filtrex.html) of the documentation for details.

To create an [Ecto](https://github.com/elixir-lang/ecto) query, simple construct a query like the following and then pipe it into oblivion!

```elixir
Filtrex.query(filter, YourApp.YourModel, __ENV__)
```

The [documentation](http://rcdilorenzo.github.io/filtrex) is filled with valuable information on how to both use and extend the library to your liking so please take a look!


## Installation

The package is not yet available yet on [Hex](https://hex.pm), but you can still install and use it:

  1. Add filtrex to your list of dependencies in `mix.exs`:

        def deps do
          [{:filtrex, github: "rcdilorenzo/filtrex"}]
        end

  2. Ensure filtrex is started before your application:

        def application do
          [applications: [:filtrex]]
        end


## Roadmap (eventual usage sample - subject to change)

```elixir
%{
  filter: %{
  type: "all"    # all | any | none
  conditions: [%{
    column: "title",
    comparator: "contains",
    value: "Buy",
    type: "text"
  }],
  sub_filters: [%{
    filter: %{
      type: "any"
      conditions: [%{
        column: "due",
        comparator: "between",
        value: %{
          start: "2015-12-22T10:00:00Z",
          end: "2015-12-29T10:00:00Z"
        }
        type: "datetime"
      }]
    }
  }]
```


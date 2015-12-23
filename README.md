# Filtrex

**TODO: Add description**

# Roadmap (eventual usage sample)

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

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed as:

  1. Add filtrex to your list of dependencies in `mix.exs`:

        def deps do
          [{:filtrex, "~> 0.0.1"}]
        end

  2. Ensure filtrex is started before your application:

        def application do
          [applications: [:filtrex]]
        end

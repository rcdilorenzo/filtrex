# Filtrex

[![Hex.pm](https://img.shields.io/hexpm/v/filtrex.svg)](https://hex.pm/packages/filtrex)
[![Build Status](https://travis-ci.org/rcdilorenzo/filtrex.svg?branch=master)](https://travis-ci.org/rcdilorenzo/filtrex)
[![Docs Status](http://inch-ci.org/github/rcdilorenzo/filtrex.svg?branch=master)](http://inch-ci.org/github/rcdilorenzo/filtrex)

Filtrex is an elixir library for parsing and querying with filter data structures and parameters. It allows construction of Ecto queries from Phoenix-like query parameters or map data structures for saving smart filters. It has been tested using the Postrgres adapter but will likely work with other adapters as well.

**Note: See the [v0.2.0 README](https://github.com/rcdilorenzo/filtrex/blob/65c51d8f0d4a8f79504f7a88bd4357db45a5c42c/README.md) for the latest Hex.pm release. This README is the documentation for the upcoming 0.3.0 version.


## Parsing Filters from URL Params

```elixir
# Get params from phoenix controller (or anywhere else)
params = %{
    "comments_contains" => "Chris McCord",
    "title" => "Upcoming Phoenix Features",
    "posted_at_between" => %{"start" => "01-01-2013", "end" => "12-31-2017"},
    "filter_union" => "any"  # special value for filter type (any | all | none)
}

# Create validation options for keys and formats
config = [
  %Filtrex.Type.Config{type: :text, keys: ~w(title comments)},
  %Filtrex.Type.Config{type: :date, keys: ~w(posted_at), options: %{format: "{0M}-{0D}-{YYYY}"}}
]


# Parse params into encodable filter structures
{:ok, filter} = Filtrex.parse_params(config, params)

# Encode filter structure into where clause on query
query = from(s in YourApp.YourModel)
  |> Filtrex.query(filter)  # => #Ecto.Query<...
```

Using parsed parameters from your phoenix application, a filter can be easily constructed with type validation and custom comparators.


## Parsing Filter Structures

```elixir

# Create validation options for keys and formats
config = [
  %Filtrex.Type.Config{type: :text, keys: ~w(title comments)},
  %Filtrex.Type.Config{type: :date, keys: ~w(due_date)},
  %Filtrex.Type.Config{type: :boolean, keys: ~w(flag)}
]

# Parse a "smart-filter" encoded from client (e.g. with Poison or Phoenix)
{:ok, filter} = Filtrex.parse(config, %{
  "filter" => %{
    "type" => "all",               # all | any | none
    "conditions" => [
      %{"column" => "title", "comparator" => "contains", "value" => "Buy", "type" => "text"},
      %{"column" => "title", "comparator" => "does not contain", "value" => "Milk", "type" => "text"},
      %{"column" => "flag", "comparator" => "equals", "value" => "false", "type" => "boolean"}
    ],
    "sub_filters" => [%{
      "filter" => %{
        "type" => "any",
        "conditions" => [
          %{"column" => "due_date", "comparator" => "equals", "value" => "2016-03-26", "type" => "date"}
        ]
      }
    }]
  }
})

query = from(m in YourApp.YourModel, where: m.rating > 90)
  |> Filtrex.query(filter)  # => #Ecto.Query<...

```


The configuration passed into `Filtrex.parse/2` gives the individual condition types more information to validate the filter against and is a required argument. See [this section](http://rcdilorenzo.github.io/filtrex/Filtrex.html) of the documentation for details.


The [documentation](http://rcdilorenzo.github.io/filtrex) is filled with valuable information on how to both use and extend the library to your liking so please take a look!

## Filter Types

The following condition types and comparators are supported.

* [Filtrex.Condition.Boolean](http://rcdilorenzo.github.io/filtrex/Filtrex.Condition.Boolean.html)
    * equals, does not equal
* [Filtrex.Condition.Text](http://rcdilorenzo.github.io/filtrex/Filtrex.Condition.Text.html)
    * equals, does not equal, contains, does not contain
* [Filtrex.Condition.Date](http://rcdilorenzo.github.io/filtrex/Filtrex.Condition.Date.html)
    * after, on or after, before, on or before, between, not between, equals, does not equal
    * options: format (default: `{YYYY}-{0M}-{0D}`)
* [Filtrex.Condition.DateTime](http://rcdilorenzo.github.io/filtrex/Filtrex.Condition.DateTime.html)
    * after, on or after, before, on or before, equals, does not equal
    * options: format (default: `{ISOz}`)
* [Filtrex.Condition.Number](http://rcdilorenzo.github.io/filtrex/Filtrex.Condition.Number.html)
    * equals, does not equal, greater than, less than or, greater than or, less than
    * options: allow_decimal (default: false), allowed_values (default: nil)

## Installation (when 0.3.0 is available)

The package is available on [Hex](https://hex.pm) and can be installed by adding it to your list of dependencies:

```elixir
def deps do
  [{:filtrex, "~> 0.3.0"}]
end
```


## License

Copyright (c) 2015 Christian Di Lorenzo

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

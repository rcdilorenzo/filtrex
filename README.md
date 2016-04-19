# Filtrex

[![Hex.pm](https://img.shields.io/hexpm/v/filtrex.svg)](https://hex.pm/packages/filtrex)
[![Build Status](https://travis-ci.org/rcdilorenzo/filtrex.svg?branch=master)](https://travis-ci.org/rcdilorenzo/filtrex)
[![Docs Status](http://inch-ci.org/github/rcdilorenzo/filtrex.svg?branch=master)](http://inch-ci.org/github/rcdilorenzo/filtrex)

Filtrex is an elixir library for parsing and querying with filter data structures and parameters. It allows construction of Ecto queries from Phoenix-like query parameters or map data structures for saving smart filters. It has been tested using the Postrgres adapter but will likely work with other adapters as well.


## Parsing Filters from URL Params

```elixir
config = [
  %Filtrex.Type.Config{type: :text, keys: ~w(title comments)},
  %Filtrex.Type.Config{type: :date, keys: ~w(posted_at), options: %{format: "{0M}-{0D}-{YYYY}"}}
]
params = %{
    "comments_contains" => "Chris McCord",
    "title" => "Upcoming Phoenix Features",
    "posted_at_between" => %{"start" => "01-01-2013", "end" => "12-31-2017"}
}
# params generated from plug (phoenix) with query string:
# "comments_contains=Chris McCord&title=Upcoming Phoenix Features&posted_at_between[start]=2013-01-01&posted_at_between[end]=2017-12-31"

{:ok, filter} = Filtrex.parse_params(config, params)
# %Filtrex{conditions: [%Filtrex.Condition.Text{column: "comments",
#     comparator: "contains", inverse: false, type: :text, value: "Chris McCord"},
#    %Filtrex.Condition.Date{column: "posted_at", comparator: "between",
#     inverse: false, type: :date,
#     value: %{end: #<Date(2017-12-31)>, start: #<Date(2013-01-01)>}},
#    %Filtrex.Condition.Text{column: "title", comparator: "equals",
#     inverse: false, type: :text, value: "Upcoming Phoenix Features"}],
#   sub_filters: [], type: "all"}

require Filtrex
Filtrex.query(filter, YourApp.YourModel)
# => #Ecto.Query<from s in YourApp.YourModel, where: fragment("(comments LIKE ?) AND ((posted_at >= ?) AND (posted_at <= ?)) AND (title = ?)", "%Chris McCord%", "2013-01-01", "2017-12-31", "Upcoming Phoenix Features")>
```

Using parsed parameters from your phoenix application, a filter can be easily constructed with type validation and custom comparators.


## Parsing Filter Structures

```elixir
config = [
  %Filtrex.Type.Config{type: :text, keys: ~w(title comments)},
  %Filtrex.Type.Config{type: :date, keys: ~w(due_date)},
  %Filtrex.Type.Config{type: :boolean, keys: ~w(flag)}
]

{:ok, filter} = Filtrex.parse(config, %{
  filter: %{
    type: "all",               # all | any | none
    conditions: [
      %{column: "title", comparator: "contains", value: "Buy", type: "text"},
      %{column: "title", comparator: "does not contain", value: "Milk", type: "text"},
      %{column: "flag", comparator: "is", value: "false", type: "boolean"}
    ],
    sub_filters: [%{
      filter: %{
        type: "any",
        conditions: [
          %{column: "due_date", comparator: "in the last", value: %{interval: "days", amount: 4}, type: "date"}
        ]
      }
    }]
  }
})

require Filtrex
Filtrex.query(filter, YourApp.YourModel)
# => #Ecto.Query<from s in Filtrex.SampleModel, where: fragment("((title LIKE ?) AND (title NOT LIKE ?) AND (flag = ?)) AND (((due_date >= ?) AND (due_date <= ?)))", "%Buy%", "%Milk%", false, "2016-03-09", "2016-03-13")>

```


The configuration passed into `Filtrex.parse/2` gives the individual condition types more information to validate the filter against and is a required argument. See [this section](http://rcdilorenzo.github.io/filtrex/Filtrex.html) of the documentation for details.

## Creating Ecto Queries from a Filtrex Filter

To create an [Ecto](https://github.com/elixir-lang/ecto) query, simply require `Filtrex` and pass in the filter and a module that uses `Ecto.Schema` to the `Filtrex.query/2` macro; then, pipe it into oblivion!

```elixir
require Filtrex

Filtrex.query(filter, YourApp.YourModel)
```

The [documentation](http://rcdilorenzo.github.io/filtrex) is filled with valuable information on how to both use and extend the library to your liking so please take a look!

## Filter Types

The following condition types and comparators are supported.

* [Filtrex.Condition.Boolean](http://rcdilorenzo.github.io/filtrex/Filtrex.Condition.Boolean.html)
    * is, is not
* [Filtrex.Condition.Text](http://rcdilorenzo.github.io/filtrex/Filtrex.Condition.Text.html)
    * is, is not, equals, does not equal, contains, does not contain
* [Filtrex.Condition.Date](http://rcdilorenzo.github.io/filtrex/Filtrex.Condition.Date.html)
    * after, on or after, before, on or before, between, not between, equals, does not equal, is, is not
    * options: format (default: `{YYYY}-{0M}-{0D}`)
* [Filtrex.Condition.DateTime](http://rcdilorenzo.github.io/filtrex/Filtrex.Condition.DateTime.html)
    * after, on or after, before, on or before, equals, does not equal, is, is not
    * options: format (default: `{ISOz}`)
* [Filtrex.Condition.Number](http://rcdilorenzo.github.io/filtrex/Filtrex.Condition.Number.html)
    * is, is not, greater than, less than or, greater than or, less than
    * options: allow_decimal (default: false), allowed_values (default: nil)

## Installation

The package is available on [Hex](https://hex.pm) and can be installed by adding it to your list of dependencies:

```elixir
def deps do
  [{:filtrex, "~> 0.2.0"}]
end
```


## License

Copyright (c) 2015 Christian Di Lorenzo

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

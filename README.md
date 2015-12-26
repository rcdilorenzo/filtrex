# Filtrex

Filtrex is an elixir library for parsing and querying with filter data structures. Although it does not direcly require [Ecto](https://github.com/elixir-lang/ecto), it is definitely geared towards using that library. Additionally, it has only been tested using the Postrgres adapter but may work with other Ecto adapters as well.

# Filter Types

The following condition types and comparators are supported. See [Usage](#usage) for the basic usage of these conditions:

* [Filtrex.Condition.Text](http://rcdilorenzo.github.io/filtrex/Filtrex.Condition.Text.html)
    * is, is not, equals, does not equal, contains, does not contain
* [Filtrex.Condition.Date](http://rcdilorenzo.github.io/filtrex/Filtrex.Condition.Date.html)
    * after, on or after, before, on or before, between, not between

## Usage

```elixir
config = %{text: %{keys: ~w(title comments)}, date: %{keys: ~w(date_due)}

{:ok, filter} = Filtrex.parse(config, %{
  filter: %{
    type: "all"                # all | any | none
    conditions: [%{
      column: "title",
      comparator: "contains",
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

## License

Copyright (c) 2015 Christian Di Lorenzo

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

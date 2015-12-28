# Filtrex

[![Hex.pm](https://img.shields.io/hexpm/v/filtrex.svg)](https://hex.pm/packages/filtrex)
[![Build Status](https://travis-ci.org/rcdilorenzo/filtrex.svg?branch=master)](https://travis-ci.org/rcdilorenzo/filtrex)
[![Docs Status](http://inch-ci.org/github/rcdilorenzo/filtrex.svg?branch=master)](http://inch-ci.org/github/rcdilorenzo/filtrex)

Filtrex is an elixir library for parsing and querying with filter data structures. Although it does not direcly require [Ecto](https://github.com/elixir-lang/ecto), it is definitely geared towards using that library. Additionally, it has only been tested using the Postrgres adapter but may work with other Ecto adapters as well.

# Filter Types

The following condition types and comparators are supported. See [Usage](#usage) for the basic usage of these conditions:

* [Filtrex.Condition.Text](http://rcdilorenzo.github.io/filtrex/Filtrex.Condition.Text.html)
    * is, is not, equals, does not equal, contains, does not contain
* [Filtrex.Condition.Date](http://rcdilorenzo.github.io/filtrex/Filtrex.Condition.Date.html)
    * after, on or after, before, on or before, between, not between, in the last, not in the last, in the next, not in the next, equals, does not equal, is, is not

## Usage

```elixir
config = %{text: %{keys: ~w(title comments)}, date: %{keys: ~w(due_date)}

{:ok, filter} = Filtrex.parse(config, %{
  filter: %{
    type: "all",               # all | any | none
    conditions: [
      %{column: "title", comparator: "contains", value: "Buy", type: "text"},
      %{column: "title", comparator: "does not contain", value: "Milk", type: "text"}
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
}
```


The configuration passed into `Filtrex.parse/2` gives the individual condition types more information to validate the filter against and is a required argument. See [this section](http://rcdilorenzo.github.io/filtrex/Filtrex.html) of the documentation for details.

To create an [Ecto](https://github.com/elixir-lang/ecto) query, simple construct a query like the following and then pipe it into oblivion!

```elixir
Filtrex.query(filter, YourApp.YourModel, __ENV__)
```

The [documentation](http://rcdilorenzo.github.io/filtrex) is filled with valuable information on how to both use and extend the library to your liking so please take a look!


## Installation

The package is available on [Hex](https://hex.pm) and can be installed with the following instructions:

  1. Add filtrex to your list of dependencies in `mix.exs`:

        def deps do
          [{:filtrex, "~> 0.1.0"}]
        end

  2. Ensure filtrex is started before your application:

        def application do
          [applications: [:filtrex]]
        end


## License

Copyright (c) 2015 Christian Di Lorenzo

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

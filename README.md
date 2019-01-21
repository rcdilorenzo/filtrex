![Banner](resources/filtrex-banner.png)

# Filtrex
[![Join the chat at https://gitter.im/filtrex-elixir/Lobby](https://badges.gitter.im/filtrex-elixir/Lobby.svg)](https://gitter.im/filtrex-elixir/Lobby?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)
[![Hex.pm](https://img.shields.io/hexpm/v/filtrex.svg)](https://hex.pm/packages/filtrex)
[![Build Status](https://travis-ci.org/rcdilorenzo/filtrex.svg?branch=master)](https://travis-ci.org/rcdilorenzo/filtrex)
[![Docs Status](http://inch-ci.org/github/rcdilorenzo/filtrex.svg?branch=master)](http://inch-ci.org/github/rcdilorenzo/filtrex)

Filtrex aims to make filtering database results with [Ecto](https://hex.pm/packages/ecto) a breeze. This library attempts to help you solve problems such as...

- Building database query filters from URL parameters
- Establishing a readable, consistent convention for filter parameters
- Validating filters do not expose unintended data or allow unauthorized access
- Saving filters for later use (e.g. a smart filter feature)

Check out the [docs](https://hexdocs.pm/filtrex/) or read on for a quick start on how to use.

_Note that this library does not require using a web dependency such as [Phoenix](https://hex.pm/packages/phoenix) but is geared towards web applications. It also has only been tested with a Postgres backing but may work with other database adapters._

## Installation

The package is available on [Hex](https://hex.pm) and can be installed by adding it to your list of dependencies:

```elixir
def deps do
  [{:filtrex, "~> 0.4.3"}]
end
```

## Outline

- [Example Usage](#example-usage)
- [Filtering from parameters](#filtering-from-parameters) (and an [example with phoenix](#example-with-phoenix))
- [Storing filters](#storing-filters)
- [Configuration](#configuration)
- [Filter Types](#filter-types)

# Example Usage

Here is a simple example of how to filter incoming parameters with filtrex:

```elixir
# in controller
defmodule MyApp.CommentController do
  use MyAppWeb, :controller

  def index(conn, params) do
    # step 1: convert and validate incoming parameters
    {:ok, filter} = MyApp.FilterConfig.comments()
      |> Filtrex.parse_params(params)

    # step 2: build query
    query = MyApp.Comment
      |> where([c], c.user_id == ^conn.assigns[:user_id])
      |> Filtrex.query(filter)

    json conn, Repo.all(query)
  end
end

# in lib/my_app/filter_config.ex
defmodule MyApp.FilterConfig do
  import Filtrex.Type.Config

  # create configuration for transforming / validating parameters
  def comments() do
    defconfig do
      text [:title, :comments]
      date :posted_at, format: "{0M}-{0D}-{YYYY}"
    end
  end
end

# reference model
defmodule MyApp.Comment do
  use Ecto.Schema

  schema "comments" do
    field :title
    field :comments
    field :posted_at, :date
  end
end
```

With this example, here are some of the query parameters that can be used:

| Example Key                         | Example Value                              |
|-------------------------------------|--------------------------------------------|
| `comments_contains`                 | Chris McCord                               |
| `title`                             | Upcoming Phoenix Features                  |
| `posted_at_between` (nested value)  | start: "01-01-2013" <br> end: "12-31-2017" |
| `filter_union` (any \| all \| none) | any                                        |

## Filtering Across Associations
Here is a more complex example for filtering across an association:

```elixir
# in controller
defmodule MyApp.CommentController do
  use MyAppWeb, :controller

  def index(conn, params) do
    # step 1: convert and validate incoming parameters
    {:ok, user_filter} = Filtrex.parse_params(user_filter(), params["user"] || %{})
    {:ok, profile_filter} = Filtrex.parse_params(profile_filter(), params["profile"] || %{})

    # step 2: build query
    user_query =
      User
      |> Filtrex.query(user_filter)

    profile_query =
      Profile
      |> Filtrex.query(profile_filter)

    # step 3: combine queries
    query =
      from(parent in user_query,
        join: pi in ^profile_query,
        on: pi.parent_id == parent.id
      )

    results = query
    |> preload([:profile])
    |> Repo.all(params)

    json conn, results
  end
end

# in lib/my_app/filter_config.ex
defmodule MyApp.FilterConfig do
  import Filtrex.Type.Config

  # create configuration for transforming / validating parameters
  def user_filter() do
    defconfig do
      text [:email]
    end
  end

  def profile_filter() do
    defconfig do
      text [:first_name]
      text [:last_name]
    end
  end
end
```
# Filtering From Parameters

Filtering from parameters is often a tedious process of special keys and validation. Filtrex standardizes this process by using a human-readable format for columns. Consider these examples:

| Query Key                | Column     | Intention     |
|--------------------------|------------|---------------|
| `comments_is_not`        | `comments` | `!=`          |
| `title_contains`         | `title`    | includes text |
| `rating_greater_than_or` | `rating`   | `>=`          |
| `posted_on_or_before`    | `posted`   | `<=`          |

Assuming that these keys are in a map along with the associated values, the parameters can be passed into filtrex with a simple configuration DSL that will validate and parse them effectively. See [Configuration](#configuration) for more details on how to create the appropriate config.

```elixir
# create necesary configuration
import Filtrex.Type.Config
config = defconfig do
  text [:title, :comments]
  date :posted
  number :rating, allow_decimal: true
end

# convert params into a validated filter
case Filtrex.parse_params(config, params) do
  {:ok, filter} ->
    # use filter to create query
    query = Filtrex.query(MyApp.Comment, filter)
  {:error, error} ->
    # e.g. {:error, "Unknown filter key 'title_means'"}
end
```

## Example with Phoenix

Here is an example of how filtrex might be used within an elixir app that uses [phoenix](http://phoenixframework.org):


```elixir
# in controller
def index(conn, params = %{"user_id" => user_id}) do
  # remove keys that are not filtered against
  filter_params = Map.drop(params, ~w(user_id))

  # create base query
  base_query = from(c in MyApp.Comment, c.user_id == ^user_id)

  # create relevant configuration
  config = MyApp.Comment.filter_options(:admin)

  # parse filter parameters
  case Filtrex.parse_params(config, filter_params) do
    {:ok, filter} ->
      # retrieve from database
      render conn, "index.json", data: Filtrex.query(base_query, filter) |> Repo.all

    {:error, error} ->
      # render filter error
      render conn, "errors.json", data: [error]
  end
end

# in model-level module
defmodule MyApp.Comment do
  import Filtrex.Type.Config
  # ...

  def filter_options(:admin) do
    defconfig do
      text :title
      date :published
      number :upvotes
      number :rating, allow_decimal: true
      boolean :flag
      datetime [:updated_at, :inserted_at]
    end
  end
end
```

With this example, a query such as this one would filter comments:

```elixir
%{
  "title_contains" => "Conf",
  "published_on_or_before" => "2016-04-01",
  "upvotes_greater_than" => 45,
  "flag" => true,
  "updated_at_after" => "2016-04-01T12:34:56Z",
  "rating_greater_than_or" => 90.5,

  "filter_union" => "any"
  # ^ filter based on any of the columns
}
```

# Storing Filters

In addition to parsing parameters, filtrex also enables parsing from a map syntax that is easily encodable to and from JSON. This feature allows storing a filter for future use (e.g. routinely checking for comments that mention "ElixirConf" or todos that are not completed).

```elixir
# create validation options for keys and formats
import Filtrex.Type.Config
config = defconfig do
  text [:title, :comments]
  date :due_date
  boolean :flag
end

# parse a filter from map syntax
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

# Encode filter structure into where clause on Ecto query
query = from(m in MyApp.Todo, where: m.rating > 90)
  |> Filtrex.query(filter)  # => #Ecto.Query<...

```

For more details on the acceptable structure of this map, feel free to take a look at the [example json schema](http://jeremydorn.com/json-editor/?schema=N4IgJgpgZglgdjALjA9nAziAXKAYjAG0QgCdtRlECJsR8jSQAaERATwAcasQUAjAFYQAxomYgOJFFxLIImHCFgMyi9l1r8ho8ZOmk5Cip27GNPdIhLwA5uIhwArgFtsAbRABDAgXGe4bOJwaDQAugC+LMJoYEioGOSsJrSeJCSegSxIEM5GSea8giJiLHoyhonRBC5wiercIJbWcHaRINHOHKmeiCiqZg1NtiBt9XXJFlbDLA4u7iB8KCjU/uLEAB4l4D00LGA7yM67IE7OfIwRLABu3o6m+YNTLSPhryzojnwA+srEJHljHipdKZEAkCAAR0cMHBYGwUG86AgWWIuUSABJwVBaABiAD0kFgCGQaHQePofxer2pLEx0FxBOg8DipPJhEp4SAAA==&value=N4IgZglgNgLgpgJxALlDAngBzikBDKKEAGhAGMB7AOwBMIYJqBnFAbVEqgFcBbK3BjCg5SlHpjwI8MCkmTlqMPBCotSGbALgAPGCRAA3AlxzyAQl3QgAvsQ4VufAfWH6xEqTLkgaFOEwACKgoYAMoqJRV9DVMQeF19I25YgFloAGsbOwVHfnkwKDwAczcKcUlpWVw4AEcuAjU4rFiAIwoHODx+UiSTXDAGnGsAXVImLhaAfUhYRBZkdnBoeDk0Ztwuq1FqOgZmNntc3BoTSZppEQVyzyr5WvqoRpjji8TjWIAmAAYARgA2AC0XwAzACPn8bMNrCNoUAAAA==&theme=bootstrap2&iconlib=fontawesome4&object_layout=grid&show_errors=interaction) or the raw [JSON schema config](resources/schema.json).

# Configuration

Each of the methods of creating a filter requires passing a configuration that filtrex then validates against. This data structure is really just a list of type configs.

```elixir
[%Filtrex.Type.Config{keys: ["title", "description"], options: %{}, type: :text},
 %Filtrex.Type.Config{keys: ["published"],  options: %{}, type: :boolean},
 %Filtrex.Type.Config{keys: ["posted_at"],  options: %{format: "{YYYY}-{0M}-{0D}"}, type: :date},
 %Filtrex.Type.Config{keys: ["updated_at"], options: %{}, type: :datetime},
 %Filtrex.Type.Config{keys: ["views"],      options: %{allow_decimal: false}, type: :number}]
```

However, for convenience and for validating the filter types, this DSL can be used to generate that exact data structure.

```elixir
import Filtrex.Type.Config

defconfig do
  # multiple text keys
  text [:title, :description]

  # boolean type
  boolean :published

  # date type with options
  date :posted_at, format: "{YYYY}-{0M}-{0D}"

  # simple datetime
  datetime :updated_at

  # integer value
  number :views, allow_decimal: false
end
```

The options passed to each type gives the individual condition types more information to validate the filter against and is a required argument. See [filter types](#filter-types) for details on the available options.


# Filter Types

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

## License

Copyright (c) 2015-2019 Christian Di Lorenzo

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

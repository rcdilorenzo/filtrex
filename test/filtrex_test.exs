defmodule FiltrexTest do
  use ExUnit.Case
  import Ecto.Query
  require Filtrex

  @config Filtrex.SampleModel.filtrex_config

  test "only allows certain types" do
    assert Filtrex.parse(@config, %{
      filter: %{type: "dash-combine", conditions: []}
    }) == {:errors, ["Invalid filter type dash-combine"]}
  end

  test "requiring more than one condition" do
    assert Filtrex.parse(@config, %{
      filter: %{type: "all", conditions: []}
    }) == {:errors, ["One or more conditions required to filter"]}
  end

  test "trickling up errors from conditions" do
    assert Filtrex.parse(@config, %{
      filter: %{type: "all", conditions: [
        %{type: "text", column: "wrong_column",
          comparator: "contains", value: "Milk"},
        %{type: "text", column: "title",
          comparator: "invalid", value: "Blah"}
      ]}
    }) == {:errors, [
      "Unknown column 'wrong_column'",
      "Invalid text comparator 'invalid'"
    ]}
  end

  test "creating an 'all' ecto filter query" do
    {:ok, filter} =  Filtrex.parse(@config, %{
      filter: %{type: "all", conditions: [
        %{type: "text", column: "title",
          comparator: "contains", value: "earth"},
        %{type: "text", column: "title",
          comparator: "does not equal",
          value: "The earth was without form and void;"}
      ]}
    })
    assert_count filter, 1
  end

  test "creating an 'any' ecto filter query" do
    {:ok, filter} =  Filtrex.parse(@config, %{
      filter: %{type: "any", conditions: [
        %{type: "date", column: "date_column",
          comparator: "on or before", value: "2016-03-20"},
        %{type: "date", column: "date_column",
          comparator: "on or after", value: "2016-05-04"}
      ]}
    })
    assert_count filter, 6
  end

  test "creating a 'none' ecto filter query" do
    {:ok, filter} =  Filtrex.parse(@config, %{
      filter: %{type: "none", conditions: [
        %{type: "text", column: "title",
          comparator: "contains", value: "earth"},
        %{type: "text", column: "title",
          comparator: "equals", value: "Chris McCord"}
      ]}
    })
    assert_count filter, 4
  end

  test "creating subfilters" do
    {:ok, filter} =  Filtrex.parse(@config, %{
      filter: %{
        type: "any",
        conditions: [
          %{type: "text", column: "title",
            comparator: "contains", value: "earth"},
          %{type: "text", column: "title",
            comparator: "equals", value: "Chris McCord"}
        ],
        sub_filters: [%{filter: %{type: "all", conditions: [
          %{type: "date", column: "date_column",
            comparator: "after", value: "2016-03-26"},
          %{type: "date", column: "date_column",
            comparator: "before", value: "2016-06-01"},
        ]}}]
      }
    })
    assert_count filter, 5
  end

  test "creating filter with numbers in the conditions" do
    {:ok, filter} =  Filtrex.parse(@config, %{
      filter: %{
        type: "all",
        conditions: [
          %{type: "number", column: "rating",
            comparator: "greater than or", value: "50"},
          %{type: "number", column: "rating",
            comparator: "less than", value: "99.9"},
          %{type: "number", column: "upvotes",
            comparator: "greater than", value: "100"},
        ]
      }
    })
    assert_count filter, 1
  end

  test "creating a filter with a datetime expression" do
    {:ok, filter} =  Filtrex.parse(@config, %{
      filter: %{type: "all", conditions: [
        %{type: "datetime", column: "datetime_column",
          comparator: "on or after", value: "2016-03-20T12:34:58.000Z"},
        %{type: "datetime", column: "datetime_column",
          comparator: "on or before", value: "2016-04-02T13:00:00.000Z"}
      ]}
    })
    assert_count filter, 1
  end

  test "parsing parameters" do
    query_string = "title_contains=earth&date_column_between[start]=2016-01-10&date_column_between[end]=2016-12-10&flag=false&filter_union=any"
    params = Plug.Conn.Query.decode(query_string)
    {:ok, filter} = Filtrex.parse_params(@config, params)
    assert filter == %Filtrex{
      type: "any",
      conditions: [
        %Filtrex.Condition.Date{
          type: :date, column: "date_column", comparator: "between", inverse: false,
          value: %{start: Timex.date({2016, 1, 10}), end: Timex.date({2016, 12, 10})}
        },
        %Filtrex.Condition.Boolean{
          type: :boolean, column: "flag",
          comparator: "equals", value: false, inverse: false
        },
        %Filtrex.Condition.Text{
          type: :text, column: "title",
          comparator: "contains", value: "earth", inverse: false
        }
      ]
    }
  end

  test "parsing string keys" do
    {:ok, filter} =  Filtrex.parse(@config, %{
      "filter" => %{"type" => "all", "conditions" => [
        %{"type" => "text", "column" => "title",
          "comparator" => "contains", "value" => "earth"},
        %{"type" => "text", "column" => "title",
          "comparator" => "does not equal",
          "value" => "The earth was without form and void;"}
      ]}
    })
    assert_count filter, 1
  end

  test "parsing invalid string keys" do
    invalid_map = %{"filter" => %{"types" => "all"}}
    assert {:error, "Unknown key 'types'"} == Filtrex.parse(@config, invalid_map)
  end

  test "pipelining to query" do
    query_string = "title_contains=earth"
    params = Plug.Conn.Query.decode(query_string)
    {:ok, filter} = Filtrex.parse_params(@config, params)
    existing_query = from(m in Filtrex.SampleModel, where: m.rating > 90)
    assert_count existing_query, filter, 1
  end

  defp assert_count(query \\ Filtrex.SampleModel, filter, count) do
    assert query
      |> Filtrex.query(filter)
      |> select([m], count(m.id))
      |> Filtrex.Repo.one! == count
  end
end

defmodule FiltrexTest do
  use ExUnit.Case
  import Ecto.Query
  require Filtrex

  @config %{text: %{keys: ["title"]}, date: %{keys: ["date_column"]}}

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
        %{type: "text", column: "wrong_column", comparator: "contains", value: "Milk"},
        %{type: "text", column: "title", comparator: "invalid", value: "Blah"}
      ]}
    }) == {:errors, ["Invalid text column 'wrong_column'", "Invalid text comparator 'invalid'"]}
  end

  test "creating an 'all' ecto filter query" do
    {:ok, filter} =  Filtrex.parse(@config, %{
      filter: %{type: "all", conditions: [
        %{type: "text", column: "title", comparator: "contains", value: "earth"},
        %{type: "text", column: "title", comparator: "is not", value: "The earth was without form and void;"}
      ]}
    })
    assert_count filter, 1
  end

  test "creating an 'any' ecto filter query" do
    {:ok, filter} =  Filtrex.parse(@config, %{
      filter: %{type: "any", conditions: [
        %{type: "date", column: "date_column", comparator: "on or before", value: "2016-03-20"},
        %{type: "date", column: "date_column", comparator: "on or after", value: "2016-05-04"}
      ]}
    })
    assert_count filter, 6
  end

  test "creating a 'none' ecto filter query" do
    {:ok, filter} =  Filtrex.parse(@config, %{
      filter: %{type: "none", conditions: [
        %{type: "text", column: "title", comparator: "contains", value: "earth"},
        %{type: "text", column: "title", comparator: "is", value: "Chris McCord"}
      ]}
    })
    assert_count filter, 4
  end

  test "creating subfilters" do
    {:ok, filter} =  Filtrex.parse(@config, %{
      filter: %{
        type: "any",
        conditions: [
          %{type: "text", column: "title", comparator: "contains", value: "earth"},
          %{type: "text", column: "title", comparator: "is", value: "Chris McCord"}
        ],
        sub_filters: [%{filter: %{type: "all", conditions: [
          %{type: "date", column: "date_column", comparator: "after", value: "2016-03-26"},
          %{type: "date", column: "date_column", comparator: "before", value: "2016-06-01"},
        ]}}]
      }
    })
    assert_count filter, 5
  end

  defp assert_count(filter, count) do
    assert Filtrex.query(filter, Filtrex.SampleModel)
      |> select([m], count(m.id))
      |> Filtrex.Repo.one! == count
  end
end

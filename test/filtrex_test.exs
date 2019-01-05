defmodule FiltrexTest do
  use ExUnit.Case
  import Ecto.Query
  alias Factory.ConditionParams
  alias Factory.FilterParams

  @config Filtrex.SampleModel.filtrex_config

  @tag :validate_structure
  test "only allows certain types" do
    assert FilterParams.build(:all)
      |> FilterParams.type("dash-combine")
      |> Filtrex.validate_structure ==
        {:error, "Invalid filter type 'dash-combine'"}
  end

  @tag :validate_structure
  test "requiring more than one condition" do
    assert FilterParams.build(:all)
      |> Filtrex.validate_structure ==
        {:error, "One or more conditions required to filter"}
  end

  @tag :validate_structure
  test "validating sub-filters is a list" do
    assert FilterParams.build(:all)
      |> FilterParams.conditions([ConditionParams.build(:text)])
      |> FilterParams.sub_filters(%{})
      |> Filtrex.validate_structure ==
        {:error, "Sub-filters must be a valid list of filters"}
  end

  @tag :validate_structure
  test "validating sub-filters recursively" do
    assert FilterParams.build(:all)
      |> FilterParams.conditions([ConditionParams.build(:text)])
      |> FilterParams.sub_filters([
          FilterParams.build(:all)
            |> FilterParams.type("blah")
            |> FilterParams.conditions([ConditionParams.build(:text)])])
      |> Filtrex.validate_structure ==
        {:error, "Invalid filter type 'blah'"}
  end

  test "trickling up errors from conditions" do
    params = FilterParams.build(:all) |> FilterParams.conditions([
      ConditionParams.build(:text, column: "wrong_column"),
      ConditionParams.build(:text, comparator: "invalid")
    ])

    assert Filtrex.parse(@config, params) ==
      {:error, "Unknown column 'wrong_column', Invalid text comparator 'invalid'"}
  end

  test "creating an 'all' ecto filter query" do
    params = FilterParams.build(:all) |> FilterParams.conditions([
      ConditionParams.build(:text, comparator: "contains", value: "earth"),
      ConditionParams.build(:text, comparator: "does not equal", value: "The earth was without form and void;")
    ])

    {:ok, filter} =  Filtrex.parse(@config, params)
    assert_count filter, 1
  end

  test "creating an 'any' ecto filter query" do
    params = FilterParams.build(:any) |> FilterParams.conditions([
      ConditionParams.build(:date, comparator: "on or before", value: "2016-03-20"),
      ConditionParams.build(:date, comparator: "on or after", value: "2016-05-04")
    ])

    {:ok, filter} =  Filtrex.parse(@config, params)
    assert_count filter, 6
  end

  test "creating a 'none' ecto filter query" do
    params = FilterParams.build(:none) |> FilterParams.conditions([
      ConditionParams.build(:text, comparator: "contains", value: "earth"),
      ConditionParams.build(:text, value: "Chris McCord")
    ])

    {:ok, filter} =  Filtrex.parse(@config, params)
    assert_count filter, 4
  end

  test "creating subfilters" do
    params = FilterParams.build(:any) |> FilterParams.conditions([
      ConditionParams.build(:text, comparator: "contains", value: "earth"),
      ConditionParams.build(:text, value: "Chris McCord")
    ]) |> FilterParams.sub_filters([
      FilterParams.build(:all) |> FilterParams.conditions([
        ConditionParams.build(:date, comparator: "after", value: "2016-03-26"),
        ConditionParams.build(:date, comparator: "before", value: "2016-06-01")
      ])
    ])

    {:ok, filter} =  Filtrex.parse(@config, params)
    assert_count filter, 5
  end

  test "creating filter with numbers in the conditions" do
    params = FilterParams.build(:all) |> FilterParams.conditions([
      ConditionParams.build(:number_rating, comparator: "greater than or", value: 50),
      ConditionParams.build(:number_rating, comparator: "less than", value: 99.9),
      ConditionParams.build(:number_upvotes, comparator: "greater than", value: 100)
    ])

    {:ok, filter} =  Filtrex.parse(@config, params)
    assert_count filter, 1
  end

  test "creating a filter with a datetime expression" do
    params = FilterParams.build(:all) |> FilterParams.conditions([
      ConditionParams.build(:datetime, comparator: "on or after", value: "2016-03-20T12:34:58.000Z"),
      ConditionParams.build(:datetime, comparator: "on or before", value: "2016-04-02T13:00:00.000Z")
    ])

    {:ok, filter} =  Filtrex.parse(@config, params)
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
          value: %{start: Timex.to_date({2016, 1, 10}), end: Timex.to_date({2016, 12, 10})}},
        %Filtrex.Condition.Boolean{
          type: :boolean, column: "flag",
          comparator: "equals", value: false, inverse: false},
        %Filtrex.Condition.Text{
          type: :text, column: "title",
          comparator: "contains", value: "earth", inverse: false}]}
  end

  test "parsing empty parameters" do
    {:ok, filter} = Filtrex.parse_params(@config, %{})
    assert_count filter, 7
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

  test "encoding" do
    filters_dump = %{
      "filter" =>
      %{
        "type" => "all",
        "conditions" => [
        %{"column" => "title", "comparator" => "contains", "value" => "Buy", "type" => "text"},
       ],
      "sub_filters" => [
          %{
            "filter" =>
            %{
              "type" => "any",
              "conditions" => [
                %{
                  "column" => "date_column",
                  "comparator" => "equals",
                  "value" => "2016-03-26",
                  "type" => "date"
                }
              ]
            }
          }
        ]
      }
    }
    {:ok, filter} = Filtrex.parse(@config, filters_dump)
    assert Filtrex.encode(filter) == filters_dump
  end

  test "pipelining to query" do
    query_string = "title_contains=earth"
    params = Plug.Conn.Query.decode(query_string)
    {:ok, filter} = Filtrex.parse_params(@config, params)
    existing_query = from(m in Filtrex.SampleModel, where: m.rating > 90.0)
    assert_count existing_query, filter, 1
  end

  test ".query returns no results if allow_empty: false" do
    results =
      Filtrex.SampleModel
      |> where([m], m.rating > 90.0)
      |> Filtrex.query(%Filtrex{empty: true}, allow_empty: false)
      |> Filtrex.Repo.all

    assert length(results) == 0
  end

  test ".safe_parse returns %Filtrex{empty: true} when error occurs" do
    invalid_map = %{"filter" => %{"types" => "all"}}
    assert %Filtrex{empty: true} == Filtrex.safe_parse(@config, invalid_map)
  end

  test ".safe_parse returns %Filtrex{} when no error occurs" do
    params = FilterParams.build(:all) |> FilterParams.conditions([
      ConditionParams.build(:text, comparator: "contains", value: "earth"),
      ConditionParams.build(:text, comparator: "does not equal", value: "The earth was without form and void;")
    ])

    assert %Filtrex{} = Filtrex.safe_parse(@config, params)
  end

  test ".safe_parse_params returns %Filtrex{empty: true} when error occurs" do
    query_string = "title_contans=earth"
    params = Plug.Conn.Query.decode(query_string)
    assert %Filtrex{empty: true} = Filtrex.safe_parse_params(@config, params)
  end

  test ".safe_parse_params returns %Filtrex{} when no error occurs" do
    query_string = "title_contains=earth&date_column_between[start]=2016-01-10&date_column_between[end]=2016-12-10&flag=false&filter_union=any"
    params = Plug.Conn.Query.decode(query_string)
    assert %Filtrex{} = Filtrex.safe_parse_params(@config, params)
  end

  defp assert_count(query \\ Filtrex.SampleModel, filter, count) do
    assert query
      |> Filtrex.query(filter)
      |> select([m], count(m.id))
      |> Filtrex.Repo.one! == count
  end
end

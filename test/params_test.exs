defmodule ParamsTest do
  use ExUnit.Case

  @config Filtrex.SampleModel.filtrex_config

  test "parsing valid text parameters" do
    params = %{"title_contains" => "blah"}
    assert Filtrex.Params.parse_conditions(@config, params) ==
      {:ok, [%Filtrex.Condition.Text{
        type: :text,
        inverse: false,
        column: "title",
        value: "blah",
        comparator: "contains"
      }]}
  end

  test "parsing valid date parameters" do
    params = %{"date_column_between" => %{"start" => "2016-03-10", "end" => "2016-03-20"}}
    assert Filtrex.Params.parse_conditions(@config, params) ==
      {:ok, [%Filtrex.Condition.Date{
        type: :date,
        inverse: false,
        column: "date_column",
        value: %{start: Timex.date({2016, 3, 10}), end: Timex.date({2016, 3, 20})},
        comparator: "between"
      }]}
  end

  test "bubbling up errors from value parsing" do
    params = %{"date_column_between" => %{"start" => "2016-03-10"}}
    assert Filtrex.Params.parse_conditions(@config, params) ==
      {:error, "Invalid date value format: Both a start and end key are required."}
  end

  test "returning error if unknown keys" do
    params = %{"title_contains" => "blah", "extra_key" => "true"}
    assert Filtrex.Params.parse_conditions(@config, params) ==
      {:error, "Unknown filter key 'extra_key'"}
  end

  test "sanitizing map keys recursively" do
    map = %{"key1" => %{"sub_key" => [%{:key => 1, "sub_sub_key" => nil}]}, "key2" => :value}

    assert Filtrex.Params.sanitize(map, [:key1, :sub_key, :sub_sub_key, :key2]) ==
      {:ok, %{key1: %{sub_key: [%{key: 1, sub_sub_key: nil}]}, key2: :value}}

    assert Filtrex.Params.sanitize(map, [:key1, :sub_sub_key, :key2]) ==
      {:error, "Unknown key 'sub_key'"}

    assert Filtrex.Params.sanitize(%{1 => "value"}, [:key1, :sub_sub_key, :key2]) ==
      {:error, "Invalid key. Only string keys are supported."}
  end
end

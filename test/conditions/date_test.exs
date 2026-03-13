defmodule FiltrexConditionDateTest do
  use ExUnit.Case
  use Timex
  import Filtrex.TestHelpers
  alias Filtrex.Condition.Date

  @column "date_column"
  @default "2015-01-01"
  @config %Filtrex.Type.Config{type: :date, keys: [@column]}
  @options_config %{@config | options: %{format: "{0M}-{0D}-{YYYY}"}}

  test "parsing errors with binary date format" do
    assert Date.parse(@config, %{
      inverse: false,
      column: @column,
      value: "2015-09-34",
      comparator: "after"
    }) == {:error, "Invalid date value format: Expected `day of month` at line 1, column 9."}

    assert Date.parse(@config, %{
      inverse: false,
      column: @column,
      value: %{start: "2015-03-01"},
      comparator: "after"
    }) == {:error, "Invalid date value for '%{start: \"201...1\"}'"}
  end

  test "parsing errors with start/end date format" do
    assert Date.parse(@config, %{
      inverse: false,
      column: @column,
      value: %{start: "2015-03-01"},
      comparator: "between"
    }) == {:error, "Invalid date value format: Both a start and end key are required."}

    assert Date.parse(@config, %{
      inverse: false,
      column: @column,
      value: %{start: "2015-03-01", end: "2015-13-21"},
      comparator: "between"
    }) == {:error, "Invalid date value format: Expected `2 digit month` at line 1, column 6."}
  end

  test "specifying different date formats" do
    assert Date.parse(@options_config, %{
      inverse: false,
      column: @column,
      value: "12-29-2016",
      comparator: "after"
    }) == {:ok, %Filtrex.Condition.Date{column: "date_column", comparator: "after",
                    inverse: false, type: :date, value: Timex.to_date({2016, 12, 29})}}
  end

  test "'equals' comparator" do
    assert Date.parse(@config, %{
      inverse: false,
      column: @column,
      value: "2016-05-18",
      comparator: "equals"
    }) |> elem(0) == :ok
  end

  test "encoding as SQL fragments for ecto" do
    assert encode(Date, @column, @default, "after")        == {"? > ?",  [column_ref(:date_column), @default]}
    assert encode(Date, @column, @default, "on or after")  == {"? >= ?", [column_ref(:date_column), @default]}
    assert encode(Date, @column, @default, "before")       == {"? < ?",  [column_ref(:date_column), @default]}
    assert encode(Date, @column, @default, "on or before") == {"? <= ?", [column_ref(:date_column), @default]}

    assert encode(Date, @column, %{start: @default, end: "2015-12-31"}, "between") ==
      {"(? >= ?) AND (? <= ?)", [column_ref(:date_column), @default, column_ref(:date_column), "2015-12-31"]}

    assert encode(Date, @column, %{start: @default, end: "2015-12-31"}, "not between") ==
      {"(? > ?) AND (? < ?)", [column_ref(:date_column), "2015-12-31", column_ref(:date_column), @default]}

    assert encode(Date, @column, "2016-03-01", "equals") ==
      {"? = ?", [column_ref(:date_column), "2016-03-01"]}

    assert encode(Date, @column, "2016-03-01", "does not equal") ==
      {"? != ?", [column_ref(:date_column), "2016-03-01"]}
  end

  defp encode(module, column, value, comparator) do
    {:ok, condition} = module.parse(@config, %{inverse: false, column: column, value: value, comparator: comparator})
    encoded = Filtrex.Encoder.encode(condition)
    {encoded.expression, encoded.values}
  end
end

defmodule FiltrexConditionDateTest do
  use ExUnit.Case
  alias Filtrex.Condition.Date

  @column "date_column"
  @default "2015-01-01"
  @config %{keys: [@column]}

  test "parsing errors with binary date format" do
    assert Date.parse(@config, %{
      inverse: false,
      column: @column,
      value: "2015-09-34",
      comparator: "after"
    }) == {:error, "Invalid date value format: Expected `day of month` at line 1, column 11."}

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
    }) == {:error, "Invalid date value format: Expected `1-2 digit month` at line 1, column 8."}
  end

  test "encoding as SQL fragments for ecto" do
    assert encode(Date, @column, @default, "after")        == {"date_column > ?",  [@default]}
    assert encode(Date, @column, @default, "on or after")  == {"date_column >= ?", [@default]}
    assert encode(Date, @column, @default, "before")       == {"date_column < ?", [@default]}
    assert encode(Date, @column, @default, "on or before") == {"date_column <= ?", [@default]}

    assert encode(Date, @column, %{start: @default, end: "2015-12-31"}, "between") ==
      {"(date_column >= ?) AND (date_column <= ?)", [@default, "2015-12-31"]}

    assert encode(Date, @column, %{start: @default, end: "2015-12-31"}, "not between") ==
      {"(date_column > ?) AND (date_column < ?)", ["2015-12-31", @default]}
  end

  defp encode(module, column, value, comparator) do
    {:ok, condition} = module.parse(@config, %{inverse: false, column: column, value: value, comparator: comparator})
    encoded = Filtrex.Encoder.encode(condition)
    {encoded.expression, encoded.values}
  end
end

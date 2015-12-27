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

  test "parsing errors with the relative date formats" do
    assert Date.parse(@config, %{
      inverse: false,
      column: @column,
      value: %{interval: "blue moon", amount: 2},
      comparator: "equals"
    }) == {:error, "Invalid date value format: 'blue moon' is not a valid interval."}

    assert Date.parse(@config, %{
      inverse: false,
      column: @column,
      value: %{interval: "weeks"},
      comparator: "in the last"
    }) == {:error, "Invalid date value format: Both an interval and amount key are required."}
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

    assert encode(Date, @column, %{interval: "weeks", amount: -1}, "equals") ==
      {"date_column = ?", [shift(:weeks, -1)]}

    assert encode(Date, @column, %{interval: "days", amount: -3}, "does not equal") ==
      {"date_column != ?", [shift(:days, -3)]}

    assert encode(Date, @column, %{interval: "months", amount: -2}, "is") ==
      {"date_column = ?", [shift(:months, -2)]}

    assert encode(Date, @column, %{interval: "days", amount: 3}, "in the last") ==
      {"(date_column >= ?) AND (date_column <= ?)", [shift(:days, -3), today]}

    assert encode(Date, @column, %{interval: "weeks", amount: 1}, "not in the last") ==
      {"(date_column < ?) AND (date_column > ?)", [shift(:weeks, -1), today]}

    assert encode(Date, @column, %{interval: "years", amount: 4}, "in the next") ==
      {"(date_column >= ?) AND (date_column <= ?)", [today, shift(:years, 4)]}

    assert encode(Date, @column, %{interval: "months", amount: 1}, "not in the next") ==
      {"(date_column < ?) AND (date_column > ?)", [today, shift(:months, 1)]}
  end

  defp encode(module, column, value, comparator) do
    {:ok, condition} = module.parse(@config, %{inverse: false, column: column, value: value, comparator: comparator})
    encoded = Filtrex.Encoder.encode(condition)
    {encoded.expression, encoded.values}
  end

  defp today do
    {:ok, date} = Timex.Date.now
      |> Timex.DateFormat.format("%Y-%m-%d", :strftime)
    date
  end

  defp shift(type, amount) do
    {:ok, date} = Timex.Date.now
      |> Timex.Date.shift([{type, amount}])
      |> Timex.DateFormat.format("%Y-%m-%d", :strftime)
    date
  end
end

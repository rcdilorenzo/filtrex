defmodule FiltrexConditionDateTimeTest do
  use ExUnit.Case
  use Timex
  import Filtrex.TestHelpers
  alias Filtrex.Condition.DateTime

  @column "datetime_column"

  @default "2016-04-01T12:30:45.000Z"
  @default_converted "2016-04-01 12:30:45.000"
  @config %Filtrex.Type.Config{type: :datetime, keys: [@column]}

  @options_default "Mon, 18 Apr 2016 13:30:45 GMT"
  @options_config %{@config | options: %{format: "{RFC1123}"}}

  test "parsing with default format" do
    assert DateTime.parse(@config, %{
      inverse: false,
      column: @column,
      value: @default,
      comparator: "after"
    }) == {:ok, %Filtrex.Condition.DateTime{column: @column, comparator: "after",
                  inverse: false, type: :datetime, value: %Elixir.DateTime{calendar: Calendar.ISO, day: 1, hour: 12,
                                                                           minute: 30, month: 4, second: 45,
                                                                           std_offset: 0, time_zone: "Etc/UTC",
                                                                           utc_offset: 0, year: 2016, zone_abbr: "UTC",
                                                                           microsecond: {0, 3}}}}
  end

  test "parsing with custom format" do
    assert DateTime.parse(@options_config, %{
      inverse: false,
      column: @column,
      value: @options_default,
      comparator: "after"
    }) == {:ok, %Filtrex.Condition.DateTime{column: @column, comparator: "after",
                  inverse: false, type: :datetime, value: Timex.to_datetime({{2016, 4, 18}, {13, 30, 45}}, "GMT")}}
  end

  test "parsing with invalid format" do
    assert DateTime.parse(@config, %{
      inverse: false,
      column: @column,
      value: @options_default,
      comparator: "after"
    }) |> elem(0) == :error
  end

  test "encoding map value" do
    assert Filtrex.Encoders.Map.encode_map_value(condition("equals", Timex.parse!(@default_converted, "{ISOdate} {ISOtime}"))) ==
      "2016-04-01 12:30:45"
  end

  test "encoding as SQL fragments for ecto" do
    assert encode(DateTime, @column, @default, "after")        == {"? > ?",  [column_ref(:datetime_column), @default_converted]}
    assert encode(DateTime, @column, @default, "on or after")  == {"? >= ?", [column_ref(:datetime_column), @default_converted]}

    assert encode(DateTime, @column, @default, "before")       == {"? < ?", [column_ref(:datetime_column), @default_converted]}
    assert encode(DateTime, @column, @default, "on or before") == {"? <= ?", [column_ref(:datetime_column), @default_converted]}

    assert encode(DateTime, @column, @default, "equals")         == {"? = ?", [column_ref(:datetime_column), @default_converted]}
    assert encode(DateTime, @column, @default, "does not equal") == {"? != ?", [column_ref(:datetime_column), @default_converted]}
  end

  defp encode(module, column, value, comparator) do
    {:ok, condition} = module.parse(@config, %{inverse: false, column: column, value: value, comparator: comparator})
    encoded = Filtrex.Encoders.Fragment.encode(condition)
    {encoded.expression, encoded.values}
  end

  defp condition(comparator, value) do
    %DateTime{type: :number, column: @column,
            inverse: false, comparator: comparator, value: value}
  end
end

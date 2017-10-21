defmodule Filtrex.Condition.DateTime do
  use Filtrex.Condition
  use Timex

  @format "{ISO:Extended}"
  @comparators ["equals", "does not equal", "after", "on or after", "before", "on or before"]

  @moduledoc """
  `Filtrex.Condition.DateTime` is a specific condition type for handling datetime filters with various comparisons.

  Configuration Options:

  | Key    | Type    | Description                                                    |
  |--------|---------|----------------------------------------------------------------|
  | format | string  | the format\* to use for parsing the incoming date string      \|
  |        |         | (defaults to {ISOz} and can use any valid Timex format)        |

  \\\* See https://hexdocs.pm/timex/Timex.Format.DateTime.Formatters.Default.html

  There are three different value formats allowed based on the type of comparator:

  | Key        | Type    | Format / Allowed Values                   |
  |------------|---------|-------------------------------------------|
  | inverse    | boolean | See `Filtrex.Condition.Text`              |
  | column     | string  | any allowed keys from passed `config`     |
  | comparator | string  | after, on or after, before, on or before,\|
  |            |         | equals, does not equal                    |
  | value      | string  | "YYYY-MM-DD'T'HH:MM:ss.SSS'Z'" ({ISOz})   |
  | type       | string  | "datetime"                                |
  """

  def type, do: :datetime

  def comparators, do: @comparators

  def parse(config, %{column: column, comparator: comparator, value: value, inverse: inverse}) do
    with {:ok, parsed_comparator} <- validate_comparator(type(), comparator, @comparators),
         {:ok, parsed_value}      <- validate_value(config, value) do
      {:ok, %__MODULE__{type: type(), inverse: inverse,
          column: column, comparator: parsed_comparator,
          value: parsed_value}}
    end
  end

  defp validate_value(config, value) do
    Timex.parse(value, config.options[:format] || @format)
  end

  defimpl Filtrex.Encoder do
    encoder "after", "before", "column > ?", &default/1
    encoder "before", "after", "column < ?", &default/1

    encoder "on or after", "on or before", "column >= ?", &default/1
    encoder "on or before", "on or after", "column <= ?", &default/1

    encoder "equals", "does not equal", "column = ?", &default/1
    encoder "does not equal", "equals", "column != ?", &default/1

    defp default(timex_date) do
      {:ok, format} = Timex.format(timex_date, "{ISOdate} {ISOtime}")
      [format]
    end
  end
end

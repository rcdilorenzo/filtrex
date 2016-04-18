defmodule Filtrex.Condition.Date do
  use Filtrex.Condition
  use Timex
  @string_date_comparators ["equals", "does not equal", "is", "is not", "after", "on or after", "before", "on or before"]
  @start_end_comparators ["between", "not between"]
  @relative_date_comparators [
    "in the last", "not in the last",
    "in the next", "not in the next"
  ]
  @comparators @string_date_comparators ++ @relative_date_comparators ++ @start_end_comparators
  @shifts [:days, :weeks, :months, :years]

  @type t :: Filtrex.Condition.Date.t
  @moduledoc """
  `Filtrex.Condition.Date` is a specific condition type for handling date filters with various comparisons.

  Configuration Options:

  | Key    | Type    | Description                                                    |
  |--------|---------|----------------------------------------------------------------|
  | format | string  | the date format\* to use for parsing the incoming date string \|
  |        |         | (defaults to YYYY-MM-DD)                                       |

  \\\* See https://hexdocs.pm/timex/Timex.Format.DateTime.Formatters.Default.html

  There are three different value formats allowed based on the type of comparator:

  | Key        | Type    | Format / Allowed Values                   |
  |------------|---------|-------------------------------------------|
  | inverse    | boolean | See `Filtrex.Condition.Text`              |
  | column     | string  | any allowed keys from passed `config`     |
  | comparator | string  | after, on or after, before, on or before,\|
  |            |         | is, is not, equals, does not equal        |
  | value      | string  | "YYYY-MM-DD"                              |
  | type       | string  | "date"                                    |

  | Key        | Type    | Format / Allowed Values                   |
  |------------|---------|-------------------------------------------|
  | inverse    | boolean | See `Filtrex.Condition.Text`              |
  | column     | string  | any allowed keys from passed `config`     |
  | comparator | string  | between, not between                      |
  | value      | map     | %{start: "YYYY-MM-DD", end: "YYYY-MM-DD"} |
  | type       | string  | "date"                                    |

  | Key        | Type    | Format / Allowed Values                                       |
  |------------|---------|---------------------------------------------------------------|
  | inverse    | boolean | See `Filtrex.Condition.Text`                                  |
  | column     | string  | any allowed keys from passed `config`                         |
  | comparator | string  | in the last, not in the last,\                                |
  |            |         | in the next, not in the next                                  |
  | value      | string  | %{interval: (days, weeks, months, or years), amount: integer} |
  | type       | string  | "date"                                                        |
  """

  def type, do: :date

  def comparators, do: @comparators

  def parse(config, %{column: column, comparator: comparator, value: value, inverse: inverse}) do
    with {:ok, parsed_comparator} <- validate_comparator(comparator),
         {:ok, parsed_value}      <- validate_value(config, parsed_comparator, value) do
      {:ok, %Condition.Date{type: :date, inverse: inverse,
          column: column, comparator: parsed_comparator,
          value: parsed_value}}
    end
  end

  defp validate_comparator(comparator) when comparator in @comparators, do:
    {:ok, comparator}
  defp validate_comparator(comparator), do:
    {:error, parse_error(comparator, :comparator, :date)}

  defp validate_value(config, comparator, value) do
    cond do
      comparator in @string_date_comparators ->
        Filtrex.Validator.Date.parse_string_date(config, value)
      comparator in @start_end_comparators ->
        Filtrex.Validator.Date.parse_start_end(config, value)
      comparator in @relative_date_comparators ->
        Filtrex.Validator.Date.parse_relative(value)
    end
  end

  defimpl Filtrex.Encoder do
    @format Filtrex.Validator.Date.format

    encoder "after", "before", "column > ?", &default/1
    encoder "before", "after", "column < ?", &default/1

    encoder "on or after", "on or before", "column >= ?", &default/1
    encoder "on or before", "on or after", "column <= ?", &default/1

    encoder "between", "not between", "(column >= ?) AND (column <= ?)", fn
      (%{start: start, end: end_value}) ->
        [default_value(start), default_value(end_value)]
    end
    encoder "not between", "between", "(column > ?) AND (column < ?)", fn
      (%{start: start, end: end_value}) ->
        [default_value(end_value), default_value(start)]
    end

    encoder "equals", "does not equal", "column = ?", &default/1
    encoder "does not equal", "equals", "column != ?", &default/1

    encoder "is", "is not", "column = ?", &default/1
    encoder "is not", "is", "column != ?", &default/1

    encoder "in the last", "not in the last", "(column >= ?) AND (column <= ?)", &in_the_last_values/1
    encoder "not in the last", "in the last", "(column < ?) AND (column > ?)", &in_the_last_values/1

    encoder "in the next", "not in the next", "(column >= ?) AND (column <= ?)", &in_the_next_values/1
    encoder "not in the next", "in the next", "(column < ?) AND (column > ?)", &in_the_next_values/1

    defp in_the_next_values(value), do: [today, date_from_relative(value)]
    defp in_the_last_values(value), do: [date_from_relative(value, :past), today]
    defp value_from_relative(value), do: [date_from_relative(value)]

    defp default(timex_date) do
      {:ok, date} = Timex.format(timex_date, @format)
      [date]
    end

    defp default_value(timex_date), do: default(timex_date) |> List.first

    defp today do
      {:ok, date} = Timex.Date.now |> Timex.format(@format)
      date
    end

    defp date_from_relative(value), do: date_from_relative(value, 1)
    defp date_from_relative(value, :past), do: date_from_relative(value, -1)
    defp date_from_relative(%{interval: interval, amount: amount}, multiplier) do
      interval = String.to_existing_atom(interval)
      {:ok, date} = Timex.Date.now
        |> Timex.Date.shift([{interval, amount * multiplier}])
        |> Timex.format(@format)
      date
    end
  end
end

defmodule Filtrex.Condition.Date do
  use Filtrex.Condition
  use Timex
  @string_date_comparators ["equals", "does not equal", "after", "on or after", "before", "on or before"]
  @start_end_comparators ["between", "not between"]
  @comparators @string_date_comparators ++ @start_end_comparators

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
  |            |         | equals, does not equal                    |
  | value      | string  | "YYYY-MM-DD"                              |
  | type       | string  | "date"                                    |

  | Key        | Type    | Format / Allowed Values                   |
  |------------|---------|-------------------------------------------|
  | inverse    | boolean | See `Filtrex.Condition.Text`              |
  | column     | string  | any allowed keys from passed `config`     |
  | comparator | string  | between, not between                      |
  | value      | map     | %{start: "YYYY-MM-DD", end: "YYYY-MM-DD"} |
  | type       | string  | "date"                                    |
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

    defp default(timex_date) do
      {:ok, date} = Timex.format(timex_date, @format)
      [date]
    end

    defp default_value(timex_date), do: default(timex_date) |> List.first
  end
end

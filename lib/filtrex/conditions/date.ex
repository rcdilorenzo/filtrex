defmodule Filtrex.Condition.Date do
  @behaviour Filtrex.Condition
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

  There are three different value formats allowed listed in each of the three tables below

  | Key        | Type    | Format / Allowed Values                  |
  |------------|---------|------------------------------------------|
  | inverse    | boolean | See `Filtrex.Condition.Text`             |
  | column     | string  | any allowed keys from passed `config`    |
  | comparator | string  | after, on or after, before, on or before |
  | value      | string  | "YYYY-MM-DD"                             |
  | type       | string  | "date"                                   |

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
  | comparator | string  | is, is not, equals, does not equal,\                          |
  |            |         | in the last, not in the last,\                                |
  |            |         | in the next, not in the next                                  |
  | value      | string  | %{interval: (days, weeks, months, or years), amount: integer} |
  | type       | string  | "date"                                                        |
  """

  import Filtrex.Condition, except: [parse: 1]
  alias Filtrex.Condition

  defstruct type: nil, column: nil, comparator: nil, value: nil, inverse: false

  def type, do: :date

  def comparators, do: @comparators

  def parse(config, %{column: column, comparator: comparator, value: value, inverse: inverse}) do
    parsed_comparator = validate_in(comparator, @comparators)
    condition = %Condition.Date{
      type: :date,
      inverse: inverse,
      column: validate_in(column, config[:keys]),
      comparator: parsed_comparator,
      value: validate_value(parsed_comparator, value)
    }
    case condition do
      %Condition.Date{column: nil} ->
        {:error, parse_error(column, :column, :date)}
      %Condition.Date{comparator: nil} ->
        {:error, parse_error(comparator, :comparator, :date)}
      %Condition.Date{value: nil} ->
        {:error, parse_value_type_error(value, :date)}
      %Condition.Date{value: error} when error != value ->
        {:error, "Invalid date value format: #{error}"}
      _ ->
        {:ok, condition}
    end
  end

  @doc false
  def validate_value(nil, _), do: nil

  def validate_value(comparator, value) do
    cond do
      comparator in @string_date_comparators ->
        Filtrex.Validator.Date.parse_string_date(value)
      comparator in @start_end_comparators ->
        Filtrex.Validator.Date.parse_start_end(value)
      comparator in @relative_date_comparators ->
        Filtrex.Validator.Date.parse_relative(value)
    end
  end

  defimpl Filtrex.Encoder do
    import Filtrex.Condition

    encoder Condition.Date, "after", "before", "column > ?"
    encoder Condition.Date, "before", "after", "column < ?"

    encoder Condition.Date, "on or after", "on or before", "column >= ?"
    encoder Condition.Date, "on or before", "on or after", "column <= ?"

    encoder Condition.Date, "between", "not between", "(column >= ?) AND (column <= ?)", fn
      (%{start: start, end: end_value}) ->
        [start, end_value]
    end
    encoder Condition.Date, "not between", "between", "(column > ?) AND (column < ?)", fn
      (%{start: start, end: end_value}) ->
        [end_value, start]
    end

    encoder Condition.Date, "equals", "does not equal", "column = ?"
    encoder Condition.Date, "does not equal", "equals", "column != ?"

    encoder Condition.Date, "is", "is not", "column = ?"
    encoder Condition.Date, "is not", "is", "column != ?"

    encoder Condition.Date, "in the last", "not in the last", "(column >= ?) AND (column <= ?)", &in_the_last_values/1
    encoder Condition.Date, "not in the last", "in the last", "(column < ?) AND (column > ?)", &in_the_last_values/1

    encoder Condition.Date, "in the next", "not in the next", "(column >= ?) AND (column <= ?)", &in_the_next_values/1
    encoder Condition.Date, "not in the next", "in the next", "(column < ?) AND (column > ?)", &in_the_next_values/1

    def in_the_next_values(value), do: [today, date_from_relative(value)]
    def in_the_last_values(value), do: [date_from_relative(value, :past), today]
    def value_from_relative(value), do: [date_from_relative(value)]

    def today do
      {:ok, date} = Timex.Date.now
        |> Timex.DateFormat.format(Filtrex.Validator.Date.format)
      date
    end

    def date_from_relative(value), do: date_from_relative(value, 1)
    def date_from_relative(value, :past), do: date_from_relative(value, -1)
    def date_from_relative(%{interval: interval, amount: amount}, multiplier) do
      interval = String.to_existing_atom(interval)
      {:ok, date} = Timex.Date.now
        |> Timex.Date.shift([{interval, amount * multiplier}])
        |> Timex.DateFormat.format(Filtrex.Validator.Date.format)
      date
    end
  end
end

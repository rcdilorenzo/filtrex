defmodule Filtrex.Condition.Date do
  @behaviour Filtrex.Condition
  @string_date_comparators ["after", "on or after", "before", "on or before"]
  @comparators [] ++ @string_date_comparators

  @type t :: Filtrex.Condition.Date.t
  @moduledoc """
  `Filtrex.Condition.Date` is a specific condition type for handling date filters with various comparisons.

  There are three different value formats allowed listed in each of the three tables below

  | Key        | Type    | Format / Allowed Values                  |
  |------------|---------|------------------------------------------|
  | inverse    | boolean | See `Filtrex.Condition.Text`             |
  | column     | string  | any                                      |
  | comparator | string  | after, on or after, before, on or before |
  | value      | string  | "YYYY-MM-DD"                             |
  | type       | string  | "date"                                   |

  TODO: Then next two types of value formats are in progress... check back later!
  """

  import Filtrex.Condition, except: [parse: 1]
  alias Filtrex.Condition

  defstruct type: nil, column: nil, comparator: nil, value: nil, inverse: false

  @doc "See `Filtrex.Condition.Text.parse/2`"
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

  def validate_value(nil, _), do: nil
  def validate_value(comparator, value) when comparator in @string_date_comparators and is_binary(value) do
    validate_date(value)
  end
  def validate_value(comparator, _) when comparator in @string_date_comparators, do: nil

  defp validate_date(value) when is_binary(value) do
    case Timex.DateFormat.parse(value, "{YYYY}-{0M}-{0D}") do
      {:ok, _} -> value
      {:error, error} -> error
    end
  end

  defimpl Filtrex.Encoder do
    import Filtrex.Condition

    encoder Condition.Date, "after", "before", "column > ?"
    encoder Condition.Date, "before", "after", "column < ?"

    encoder Condition.Date, "on or after", "on or before", "column >= ?"
    encoder Condition.Date, "on or before", "on or after", "column <= ?"
  end
end

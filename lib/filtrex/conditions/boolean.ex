defmodule Filtrex.Condition.Boolean do
  use Filtrex.Condition

  @type t :: Filtrex.Condition.Boolean
  @moduledoc """
  `Filtrex.Condition.Boolean` is a specific ondition type for handling boolean flags. It allows an empty string for false value as well as string representations "true" and "false". Its comparators only consist of "is" or "is not".
  """

  def type, do: :boolean

  def comparators, do: ["is", "is not"]

  def parse(config, %{column: column, comparator: comparator, value: value, inverse: inverse}) do
    parsed_comparator = validate_in(comparator, comparators)

    condition = %Condition.Boolean{
      type: type,
      inverse: inverse,
      column: validate_in(column, config[:keys]),
      comparator: parsed_comparator,
      value: validate_value(value)
    }

    case condition do
      %Condition.Boolean{column: nil} ->
        {:error, parse_error(column, :column, :date)}
      %Condition.Boolean{comparator: nil} ->
        {:error, parse_error(comparator, :comparator, :date)}
      %Condition.Boolean{value: nil} ->
        {:error, parse_value_type_error(value, :boolean)}
      _ ->
        {:ok, condition}
    end
  end

  defp validate_value(""), do: false
  defp validate_value("true"), do: true
  defp validate_value("false"), do: false
  defp validate_value(bool) when is_boolean(bool), do: bool
  defp validate_value(_), do: nil

  defimpl Filtrex.Encoder do
    encoder "is", "is not", "column = ?"
    encoder "is not", "is", "column != ?"
  end
end

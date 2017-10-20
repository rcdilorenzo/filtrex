defmodule Filtrex.Condition.Boolean do
  use Filtrex.Condition

  @type t :: Filtrex.Condition.Boolean
  @moduledoc """
  `Filtrex.Condition.Boolean` is a specific ondition type for handling boolean flags. It allows an empty string for false value as well as string representations "true" and "false". Its comparators only consist of "equals" or "does not equal". There are no configuration options for the boolean condition.
  """

  def type, do: :boolean

  def comparators, do: ["equals", "does not equal"]

  def parse(_config, %{column: column, comparator: comparator, value: value, inverse: inverse}) do
    parsed_comparator = validate_in(comparator, comparators())

    condition = %Condition.Boolean{
      type: type(),
      inverse: inverse,
      column: column,
      comparator: parsed_comparator,
      value: validate_value(value)
    }

    case condition do
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
    encoder "equals", "does not equal", "column = ?"
    encoder "does not equal", "equals", "column != ?"
  end
end

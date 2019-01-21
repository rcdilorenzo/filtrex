defmodule Filtrex.Condition.Number do
  use Filtrex.Condition

  @type t :: Filtrex.Condition.Number
  @moduledoc """
  `Filtrex.Condition.Number` is a specific condition type for handling
  integer and decimal filters with various configuration options.

  Comparators:
    greater than, less than or,
    greater than or, less than

  Configuation Options:

  | Key            | Type        | Description                      |
  |----------------|-------------|----------------------------------|
  | allow_decimal  | true/false  | required to allow decimal values |
  | allowed_values | list/range  | value must be in these values    |
  """

  def type, do: :number

  def comparators, do: [
    "equals", "does not equal",
    "greater than", "less than or",
    "greater than or", "less than"
  ]

  def parse(config, %{column: column, comparator: comparator, value: value, inverse: inverse}) do
    result = with {:ok, parsed_value} <- parse_value(config.options, value),
      do: %Condition.Number{type: type(), inverse: inverse, value: parsed_value, column: column,
        comparator: validate_in(comparator, comparators())}

    case result do
      {:error, error} ->
        {:error, error}
      %Condition.Number{comparator: nil} ->
        {:error, parse_error(column, :comparator, type())}
      %Condition.Number{value: nil} ->
        {:error, parse_value_type_error(value, type())}
      _ ->
        {:ok, result}
    end
  end

  defp parse_value(options = %{allow_decimal: true}, string) when is_binary(string) do
    case Float.parse(string) do
      {float, ""} -> parse_value(options, float)
      _           -> {:error, parse_value_type_error(string, type())}
    end
  end

  defp parse_value(options, string) when is_binary(string) do
    case Integer.parse(string) do
      {integer, ""} -> parse_value(options, integer)
      _             -> {:error, parse_value_type_error(string, type())}
    end
  end

  defp parse_value(options, float) when is_float(float) do
    allowed_values = options[:allowed_values]
    cond do
      options[:allow_decimal] == false ->
        {:error, parse_value_type_error(float, type())}
      allowed_values == nil ->
        {:ok, float}
      Range.range?(allowed_values) ->
        start..final = allowed_values
        if float >= start and float <= final do
          {:ok, float}
        else
          {:error, "Provided number value not allowed"}
        end
      is_list(allowed_values) and float in allowed_values ->
        {:ok, float}
      is_list(allowed_values) and float not in allowed_values ->
        {:error, "Provided number value not allowed"}
    end
  end

  defp parse_value(options, integer) when is_integer(integer) do
    allowed_values = options[:allowed_values]
    cond do
      allowed_values == nil or integer in allowed_values ->
        {:ok, integer}
      integer not in allowed_values ->
        {:error, "Provided number value not allowed"}
    end
  end

  defp parse_value(_, value), do: {:error, parse_value_type_error(value, type())}

  defimpl Filtrex.Encoder do
    encoder "equals", "does not equal", "column = ?"
    encoder "does not equal", "equals", "column != ?"
    encoder "greater than", "less than or", "column > ?"
    encoder "less than or", "greater than", "column <= ?"
    encoder "less than", "greater than or", "column < ?"
    encoder "greater than or", "less than", "column >= ?"
  end
end

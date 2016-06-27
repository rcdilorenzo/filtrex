defmodule Filtrex.Condition.Text do
  use Filtrex.Condition
  @comparators ["equals", "does not equal", "contains", "does not contain"]

  @type t :: Filtrex.Condition.Text.t
  @moduledoc """
  `Filtrex.Condition.Text` is a specific condition type for handling text filters with various comparisons. There are no configuration options for the date condition.

  It accepts the following format (where `inverse` is passed directly from `Filtrex.Condition`):
  ```
  %{
    inverse: boolean,
    column: string,
    comparator: string,  # equals, does not equal, contains, does not contain
    value: string,
    type: "text"
  }
  ```
  """

  def type, do: :text

  def comparators, do: @comparators

  @doc """
  Tries to create a valid text condition struct, calling helper methods
  from `Filtrex.Condition` to validate each type. If any of the types are not valid,
  it accumulates the errors and returns them.
  """
  def parse(_config, %{column: column, comparator: comparator, value: value, inverse: inverse}) do
    condition = %Condition.Text{
      type: :text,
      inverse: inverse,
      column: column,
      comparator: validate_in(comparator, @comparators),
      value: validate_is_binary(value)
    }
    case condition do
      %Condition.Text{comparator: nil} ->
        {:error, parse_error(comparator, :comparator, :text)}
      %Condition.Text{value: nil} ->
        {:error, parse_value_type_error(column, :text)}
      _ ->
        {:ok, condition}
    end
  end

  defimpl Filtrex.Encoder do
    encoder "equals", "does not equal", "column = ?"
    encoder "does not equal", "equals", "column != ?"

    encoder "contains", "does not contain", "lower(column) LIKE lower(?)", &(["%#{&1}%"])
    encoder "does not contain", "contains", "lower(column) NOT LIKE lower(?)", &(["%#{&1}%"])
  end
end

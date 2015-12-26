defmodule Filtrex.Condition.Text do
  @behaviour Filtrex.Condition
  @comparators ["equals", "does not equal", "is", "is not", "contains", "does not contain"]

  @type t :: Filtrex.Condition.Text.t
  @moduledoc """
  `Filtrex.Condition.Text` is a specific condition type for handling text filters with various comparisons.

  It accepts the following format (where `inverse` is passed directly from `Filtrex.Condition`):
  ```
  %{
    inverse: boolean,
    column: string,
    comparator: string,  # equals, is, is not, contains, does not contain
    value: string,
    type: "text"
  }
  ```
  """

  import Filtrex.Condition, except: [parse: 1]
  alias Filtrex.Condition

  defstruct type: nil, column: nil, comparator: nil, value: nil, inverse: false

  @doc """
  Tries to create a valid text condition struct, calling helper methods
  from `Filtrex.Condition` to validate each type. If any of the types are not valid,
  it accumulates the errors and returns them.
  """
  def parse(config, %{column: column, comparator: comparator, value: value, inverse: inverse}) do
    condition = %Condition.Text{
      type: :text,
      inverse: inverse,
      column: validate_in(column, config[:keys]),
      comparator: validate_in(comparator, @comparators),
      value: validate_is_binary(value)
    }
    case condition do
      %Condition.Text{column: nil} ->
        {:error, parse_error(column, :column, :text)}
      %Condition.Text{comparator: nil} ->
        {:error, parse_error(comparator, :comparator, :text)}
      %Condition.Text{value: nil} ->
        {:error, parse_value_type_error(column, :text)}
      _ ->
        {:ok, condition}
    end
  end

  defimpl Filtrex.Encoder do
    import Filtrex.Condition

    encoder Condition.Text, "is", "is not", "column = ?"
    encoder Condition.Text, "is not", "is", "column != ?"

    encoder Condition.Text, "equals", "does not equal", "column = ?"
    encoder Condition.Text, "does not equal", "equals", "column != ?"

    encoder Condition.Text, "contains", "does not contain", "column LIKE ?", ["%value%"]
    encoder Condition.Text, "does not contain", "contains", "column NOT LIKE ?", ["%value%"]
  end
end

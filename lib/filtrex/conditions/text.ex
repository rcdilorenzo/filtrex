defmodule Filtrex.Condition.Text do
  @behaviour Filtrex.Condition
  @comparators ["equals", "is", "is not", "contains", "does not contain"]

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
    def encode(condition = %Condition.Text{comparator: comparator, inverse: true}) when comparator in ~w(is equals) do
      condition |> struct(inverse: false, comparator: "is not") |> encode
    end

    def encode(%Condition.Text{column: column, comparator: comparator, value: value}) when comparator in ~w(is equals) do
      %Filtrex.Fragment{expression: "#{column} = ?", values: [value]}
    end

    def encode(condition = %Condition.Text{comparator: "is not", inverse: true}) do
      condition |> struct(inverse: false, comparator: "is") |> encode
    end

    def encode(%Condition.Text{column: column, comparator: "is not", value: value}) do
      %Filtrex.Fragment{expression: "#{column} != ?", values: [value]}
    end

    def encode(condition = %Condition.Text{comparator: "contains", inverse: true}) do
      condition |> struct(inverse: false, comparator: "does not contain") |> encode
    end

    def encode(%Condition.Text{column: column, comparator: "contains", value: value}) do
      %Filtrex.Fragment{expression: "#{column} LIKE ?", values: ["%#{value}%"]}
    end

    def encode(condition = %Condition.Text{comparator: "does not contain", inverse: true}) do
      condition |> struct(inverse: false, comparator: "contains") |> encode
    end

    def encode(%Condition.Text{column: column, comparator: "does not contain", value: value}) do
      %Filtrex.Fragment{expression: "#{column} NOT LIKE ?", values: ["%#{value}%"]}
    end
  end

end

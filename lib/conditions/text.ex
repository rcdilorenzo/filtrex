defmodule Filtrex.Condition.Text do
  @behaviour Filtrex.Condition
  @comparators ["equals", "is", "is not", "contains", "does not contain"] #...

  import Filtrex.Condition, except: [parse: 1]
  alias Filtrex.Condition

  defstruct type: nil, column: nil, comparator: nil, value: nil

  def parse(config, %{column: column, comparator: comparator, value: value}) do
    condition = %Condition.Text{
      type: :text,
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
    def encode(%Condition.Text{column: column, comparator: comparator, value: value}) when comparator in ~w(is equals) do
      %Filtrex.Fragment{expression: "#{column} = ?", values: [value]}
    end

    def encode(%Condition.Text{column: column, comparator: "is not", value: value}) do
      %Filtrex.Fragment{expression: "#{column} IS NOT ?", values: [value]}
    end

    def encode(%Condition.Text{column: column, comparator: "contains", value: value}) do
      %Filtrex.Fragment{expression: "#{column} LIKE %?%", values: [value]}
    end

    def encode(%Condition.Text{column: column, comparator: "does not contain", value: value}) do
      %Filtrex.Fragment{expression: "#{column} NOT LIKE %?%", values: [value]}
    end
  end

end

defprotocol Filtrex.Encoder do
  @moduledoc """
  Encodes a condition into `Filtrex.Fragment` as an expression with values.
  Implementing this protocol is required for any new conditions.
  See `Filtrex.Utils.Encoder` for helper methods with this implementation.

  Example:
  ```
  defimpl Filtrex.Encoder, for: Filtrex.Condition.Text do
    def encode(%Filtrex.Condition.Text{column: column, comparator: "equals", value: value}) do
      %Filtrex.Fragment{expression: "\#\{column\} = ?", values: [value]}
    end
  end
  ```
  """

  @doc "The function that performs the encoding"
  @spec encode(Filter.Condition.t) :: [String.t | [any]]
  def encode(condition)
end

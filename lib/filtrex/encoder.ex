defprotocol Filtrex.Encoder do
  @moduledoc """
  Encodes a condition into `Filtrex.Fragment` as an expression with values

  Example:
  ```
  defimpl Filtrex.Encoder, for: Filtrex.Condition.Text do
    def encode(%Filtrex.Condition.Text{column: column, comparator: "is", value: value}) do
      %Filtrex.Fragment{expression: "\#\{column\} = ?", values: [value]}
    end
  end
  ```
  """

  @spec encode(Filter.Condition.t) :: [String.t | [any]]
  def encode(condition)
end

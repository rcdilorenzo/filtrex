defmodule FiltrexConditionTextTest do
  use ExUnit.Case
  import Filtrex.TestHelpers
  alias Filtrex.Condition.Text
  alias Filtrex.Encoders.Fragment

  @config Filtrex.SampleModel.filtrex_config

  test "parsing errors" do
    assert {:error, "Invalid text value for title"} == Text.parse(@config, %{
      inverse: false,
      column: "title",
      value: %{},
      comparator: "equals"
    })
    assert {:error, "Invalid text comparator 'between'"} == Text.parse(@config, %{
      inverse: false,
      column: "title",
      value: "Buy Milk",
      comparator: "between"
    })
  end

  test "encoding map value" do
    text = "Lorem Ipsum"
    assert Filtrex.Encoders.Map.encode_map_value(condition("equals", text)) == text
  end

  test "encoding as SQL fragments for ecto" do
    {:ok, condition} = Text.parse(@config, %{inverse: false, column: "title", value: "Buy Milk", comparator: "equals"})
    encoded = Fragment.encode(condition)
    assert encoded.values == [column_ref(:title), "Buy Milk"]
    assert encoded.expression == "? = ?"

    {:ok, condition} = Text.parse(@config, %{inverse: false, column: "title", value: "Buy Milk", comparator: "does not equal"})
    encoded = Fragment.encode(condition)
    assert encoded.expression == "? != ?"

    {:ok, condition} = Text.parse(@config, %{inverse: false, column: "title", value: "Buy Milk", comparator: "contains"})
    encoded = Fragment.encode(condition)
    assert encoded.expression == "lower(?) LIKE lower(?)"

    {:ok, condition} = Text.parse(@config, %{inverse: false, column: "title", value: "Buy Milk", comparator: "does not contain"})
    encoded = Fragment.encode(condition)
    assert encoded.expression == "lower(?) NOT LIKE lower(?)"
    assert encoded.values == [column_ref(:title), "%Buy Milk%"]
  end

  defp condition(comparator, value) do
    %Text{type: :text, column: @column,
          inverse: false, comparator: comparator, value: value}
  end

end

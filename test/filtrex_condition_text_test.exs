defmodule FiltrexConditionTextTest do
  use ExUnit.Case
  alias Filtrex.Condition.Text

  @config %{keys: ["title"]}

  test "parsing errors" do
    assert {:error, "Invalid text column 'due'"} == Text.parse(@config, %{
      column: "due",
      value: "Buy Milk",
      comparator: "equals"
    })
    assert {:error, "Invalid text value for title"} == Text.parse(@config, %{
      column: "title",
      value: %{},
      comparator: "equals"
    })
    assert {:error, "Invalid text comparator 'between'"} == Text.parse(@config, %{
      column: "title",
      value: "Buy Milk",
      comparator: "between"
    })
  end

  test "encoding as SQL fragments for ecto" do
    {:ok, condition} = Text.parse(@config, %{column: "title", value: "Buy Milk", comparator: "equals"})
    encoded = Filtrex.Encoder.encode(condition)
    assert encoded.values == ["Buy Milk"]
    assert encoded.expression == "title = ?"

    {:ok, condition} = Text.parse(@config, %{column: "title", value: "Buy Milk", comparator: "is not"})
    encoded = Filtrex.Encoder.encode(condition)
    assert encoded.expression == "title IS NOT ?"

    {:ok, condition} = Text.parse(@config, %{column: "title", value: "Buy Milk", comparator: "contains"})
    encoded = Filtrex.Encoder.encode(condition)
    assert encoded.expression == "title LIKE %?%"

    {:ok, condition} = Text.parse(@config, %{column: "title", value: "Buy Milk", comparator: "does not contain"})
    encoded = Filtrex.Encoder.encode(condition)
    assert encoded.expression == "title NOT LIKE %?%"
  end
end

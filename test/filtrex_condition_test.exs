defmodule FiltrexConditionTest do
  use ExUnit.Case

  @config %{
    text: %{keys: ["title"]}
  }

  test "finding the right type of condition" do
    {:ok, condition} = Filtrex.Condition.parse(@config, %{
      type: "text",
      column: "title",
      value: "Buy Milk",
      comparator: "equals"
    })
    assert condition.__struct__ == Filtrex.Condition.Text
  end
end

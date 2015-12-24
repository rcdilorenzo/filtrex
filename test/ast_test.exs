defmodule FiltrexASTTest do
  use ExUnit.Case

  @conditions [
    %Filtrex.Condition.Text{column: "title", comparator: "contains", value: "created"},
    %Filtrex.Condition.Text{column: "title", comparator: "is not", value: "Chris McCord"}
  ]

  test "building an ecto query expression" do
    ast = Filtrex.AST.build_query(@conditions, Filtrex.SampleModel, "AND")
    expression = Macro.to_string(quote do: unquote(ast))
    assert expression == "from(s in Filtrex.SampleModel, where: fragment(\"(title LIKE ?) AND (title != ?)\", \"%created%\", \"Chris McCord\"))"
  end
end

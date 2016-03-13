defmodule FiltrexASTTest do
  use ExUnit.Case
  use Timex

  @filter %Filtrex{type: "any", conditions: [
    %Filtrex.Condition.Text{column: "title", comparator: "contains", value: "created"},
    %Filtrex.Condition.Text{column: "title", comparator: "is not", value: "Chris McCord"}
  ], sub_filters: [
    %Filtrex{type: "all", conditions: [
      %Filtrex.Condition.Date{column: "date_column", comparator: "after", value: Timex.date({2016, 5, 1})},
      %Filtrex.Condition.Date{column: "date_column", comparator: "before", value: Timex.date({2017, 1, 1})}
    ]}
  ]}

  test "building an ecto query expression" do
    ast = Filtrex.AST.build_query(@filter, Filtrex.SampleModel)
    expression = Macro.to_string(quote do: unquote(ast))
    assert with_newline(expression) == """
    from(s in Filtrex.SampleModel, where: fragment("((title LIKE ?) OR (title != ?)) OR ((date_column > ?) AND (date_column < ?))", "%created%", "Chris McCord", "2016-05-01", "2017-01-01"))
    """
  end

  defp with_newline(string), do: "#{string}\n"
end

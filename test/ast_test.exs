defmodule FiltrexASTTest do
  use ExUnit.Case
  use Timex

  @filter %Filtrex{type: "any", conditions: [
    %Filtrex.Condition.Text{column: "title", comparator: "contains", value: "created"},
    %Filtrex.Condition.Text{column: "title", comparator: "does not equal", value: "Chris McCord"}
  ], sub_filters: [
    %Filtrex{type: "all", conditions: [
      %Filtrex.Condition.Date{column: "date_column", comparator: "after", value: Timex.to_date({2016, 5, 1})},
      %Filtrex.Condition.Date{column: "date_column", comparator: "before", value: Timex.to_date({2017, 1, 1})}
    ]}
  ]}

  test "building an ecto query expression" do
    ast = Filtrex.AST.build_query(Filtrex.SampleModel, @filter)
    expression = Macro.to_string(quote do: unquote(ast))
    # Normalize whitespace for cross-version compatibility (Macro.to_string formatting varies)
    normalized = expression |> String.replace(~r/\s+/, " ") |> String.trim()
    assert normalized =~ "Ecto.Query.where("
    assert normalized =~ "Filtrex.SampleModel"
    assert normalized =~ ~s|"((lower(?) LIKE lower(?)) OR (? != ?)) OR ((? > ?) AND (? < ?))"|
    assert normalized =~ "s.title"
    assert normalized =~ ~s("%created%")
    assert normalized =~ ~s("Chris McCord")
    assert normalized =~ "s.date_column"
    assert normalized =~ ~s("2016-05-01")
    assert normalized =~ ~s("2017-01-01")
  end
end

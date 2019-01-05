defmodule FiltrexConditionBooleanTest do
  use ExUnit.Case
  import Filtrex.TestHelpers
  alias Filtrex.Condition.Boolean

  @column "flag"
  @config %{keys: [@column]}

  test "parsing true condition" do
    assert Boolean.parse(@config, params("true")) ==
      {:ok, condition(true)}
    assert Boolean.parse(@config, params(true)) ==
      {:ok, condition(true)}
  end

  test "parsing false/empty condition" do
    assert Boolean.parse(@config, params("")) ==
      {:ok, condition(false)}
    assert Boolean.parse(@config, params("false")) ==
      {:ok, condition(false)}
  end


  test "throwing error for non-boolean value" do
    assert Boolean.parse(@config, params("blah")) ==
      {:error, "Invalid boolean value for blah"}
  end

  test "encoding map value" do
    assert Filtrex.Encoders.Map.encode_map_value(condition(false)) == "false"
    assert Filtrex.Encoders.Map.encode_map_value(condition(true)) == "true"
  end

  test "encoding true value" do
    assert Filtrex.Encoders.Fragment.encode(condition(true, "equals")) ==
      %Filtrex.Fragment{expression: "? = ?", values: [column_ref(:flag), true]}

    assert Filtrex.Encoders.Fragment.encode(condition(true, "does not equal")) ==
      %Filtrex.Fragment{expression: "? != ?", values: [column_ref(:flag), true]}
  end

  test "encoding false value" do
    assert Filtrex.Encoders.Fragment.encode(condition(false, "equals")) ==
      %Filtrex.Fragment{expression: "? = ?", values: [column_ref(:flag), false]}

    assert Filtrex.Encoders.Fragment.encode(condition(false, "does not equal")) ==
      %Filtrex.Fragment{expression: "? != ?", values: [column_ref(:flag), false]}
  end

  defp params(value) do
    %{inverse: false,
      column: @column,
      value: value,
      comparator: "equals"}
  end

  defp condition(value, comparator \\ "equals") do
    %Boolean{type: :boolean, column: @column,
      inverse: false, comparator: comparator, value: value}
  end
end

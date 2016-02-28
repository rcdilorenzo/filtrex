defmodule FiltrexConditionBooleanTest do
  use ExUnit.Case
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

  test "encoding true value" do
    assert Filtrex.Encoder.encode(condition(true, "is")) ==
      %Filtrex.Fragment{expression: "flag = ?", values: [true]}

    assert Filtrex.Encoder.encode(condition(true, "is not")) ==
      %Filtrex.Fragment{expression: "flag != ?", values: [true]}
  end

  test "encoding false value" do
    assert Filtrex.Encoder.encode(condition(false, "is")) ==
      %Filtrex.Fragment{expression: "flag = ?", values: [false]}

    assert Filtrex.Encoder.encode(condition(false, "is not")) ==
      %Filtrex.Fragment{expression: "flag != ?", values: [false]}
  end

  defp params(value) do
    %{inverse: false,
      column: @column,
      value: value,
      comparator: "is"}
  end

  defp condition(value, comparator \\ "is") do
    %Boolean{type: :boolean, column: @column,
      inverse: false, comparator: comparator, value: value}
  end
end

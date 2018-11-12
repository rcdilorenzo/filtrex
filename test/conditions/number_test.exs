defmodule FiltrexConditionNumberTest do
  use ExUnit.Case
  import Filtrex.TestHelpers
  alias Filtrex.Condition.Number

  @column "age"
  @config %Filtrex.Type.Config{type: :number, keys: [@column],
            options: %{allowed_values: 1..100, allow_decimal: true}}

  test "parsing integer successfully" do
    assert Number.parse(@config, params("equals", "10")) ==
      {:ok, condition("equals", 10)}

    assert Number.parse(@config, params("equals", "1")) ==
      {:ok, condition("equals", 1)}

    assert Number.parse(@config, params("equals", 5)) ==
      {:ok, condition("equals", 5)}

    assert Number.parse(put_in(@config.options[:allow_decimal], false), params("equals", 5)) ==
      {:ok, condition("equals", 5)}
  end

  test "parsing float successfully" do
    assert Number.parse(@config, params("equals", "3.5")) ==
      {:ok, condition("equals", 3.5)}
  end

  test "parsing number errors" do
    assert Number.parse(@config, params("equals", "blah")) ==
      {:error, "Invalid number value for blah"}

    assert Number.parse(@config, params("equals", "")) ==
      {:error, "Invalid number value for "}

    assert Number.parse(@config, params("equals", nil)) ==
      {:error, "Invalid number value for 'nil'"}


    assert Number.parse(put_in(@config.options[:allow_decimal], false), params("equals", "10.5")) ==
      {:error, "Invalid number value for 10.5"}
  end

  test "dumping numbers" do
    assert Number.dump_value(123) == "123"
  end

  test "validating range of allowed integer values" do
    assert Number.parse(@config, params("equals", "101")) ==
      {:error, "Provided number value not allowed"}

    assert Number.parse(@config, params("equals", "-1")) ==
      {:error, "Provided number value not allowed"}
  end

  test "validating range of allowed float values" do
    assert Number.parse(@config, params("equals", "100.5")) ==
      {:error, "Provided number value not allowed"}
  end

  test "encoding 'greater than'" do
    assert Filtrex.Encoders.FragmentEncoder.encode(condition("greater than", 10)) ==
      %Filtrex.Fragment{expression: "? > ?", values: [column_ref(:age), 10]}
  end

  defp params(comparator, value) do
    %{inverse: false,
      column: @column,
      value: value,
      comparator: comparator}
  end

  defp condition(comparator, value) do
    %Number{type: :number, column: @column,
      inverse: false, comparator: comparator, value: value}
  end
end

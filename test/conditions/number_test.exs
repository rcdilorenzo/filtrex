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

  test "validating list of allowed integer values" do
    list_config = %{@config | options: %{allowed_values: [1, 5, 10], allow_decimal: false}}

    assert Number.parse(list_config, params("equals", "5")) ==
      {:ok, condition("equals", 5)}

    assert Number.parse(list_config, params("equals", "7")) ==
      {:error, "Provided number value not allowed"}
  end

  test "validating list of allowed float values" do
    list_config = %{@config | options: %{allowed_values: [1.5, 3.5, 5.0], allow_decimal: true}}

    assert Number.parse(list_config, params("equals", "3.5")) ==
      {:ok, condition("equals", 3.5)}

    assert Number.parse(list_config, params("equals", "2.0")) ==
      {:error, "Provided number value not allowed"}
  end

  test "parsing without allowed_values option" do
    no_limit_config = %{@config | options: %{allow_decimal: true}}

    assert Number.parse(no_limit_config, params("equals", "999")) ==
      {:ok, condition("equals", 999)}

    assert Number.parse(no_limit_config, params("equals", "3.14")) ==
      {:ok, condition("equals", 3.14)}
  end

  test "encoding 'equals'" do
    assert encode("equals", 10) == {"? = ?", [column_ref(:age), 10]}
  end

  test "encoding 'does not equal'" do
    assert encode("does not equal", 10) == {"? != ?", [column_ref(:age), 10]}
  end

  test "encoding 'greater than'" do
    assert encode("greater than", 10) == {"? > ?", [column_ref(:age), 10]}
  end

  test "encoding 'less than or'" do
    assert encode("less than or", 10) == {"? <= ?", [column_ref(:age), 10]}
  end

  test "encoding 'less than'" do
    assert encode("less than", 10) == {"? < ?", [column_ref(:age), 10]}
  end

  test "encoding 'greater than or'" do
    assert encode("greater than or", 10) == {"? >= ?", [column_ref(:age), 10]}
  end

  test "encoding with inverse reverses comparator" do
    encoded = Filtrex.Encoder.encode(%Number{
      type: :number, column: @column,
      inverse: true, comparator: "equals", value: 10
    })
    assert {encoded.expression, encoded.values} == {"? != ?", [column_ref(:age), 10]}

    encoded = Filtrex.Encoder.encode(%Number{
      type: :number, column: @column,
      inverse: true, comparator: "greater than", value: 10
    })
    assert {encoded.expression, encoded.values} == {"? <= ?", [column_ref(:age), 10]}

    encoded = Filtrex.Encoder.encode(%Number{
      type: :number, column: @column,
      inverse: true, comparator: "less than", value: 10
    })
    assert {encoded.expression, encoded.values} == {"? >= ?", [column_ref(:age), 10]}
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

  defp encode(comparator, value) do
    encoded = Filtrex.Encoder.encode(condition(comparator, value))
    {encoded.expression, encoded.values}
  end
end

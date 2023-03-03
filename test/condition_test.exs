defmodule FiltrexConditionTest do
  use ExUnit.Case

  @config Filtrex.SampleModel.filtrex_config()
  @text_config %Filtrex.Type.Config{keys: ["title"], options: %{}, type: :text}
  @date_config %Filtrex.Type.Config{keys: ["date_column"], options: %{}, type: :date}

  test "finding the right type of condition" do
    {:ok, condition} =
      Filtrex.Condition.parse(@config, %{
        inverse: false,
        type: "text",
        column: "title",
        value: "Buy Milk",
        comparator: "equals"
      })

    assert condition.__struct__ == Filtrex.Condition.Text
  end

  test "determining whether params key matches" do
    assert Filtrex.Condition.param_key_type(@config, "title_contains") ==
             {:ok, Filtrex.Condition.Text, @text_config, "title", "contains"}

    assert Filtrex.Condition.param_key_type(@config, "date_column_on_or_after") ==
             {:ok, Filtrex.Condition.Date, @date_config, "date_column", "on or after"}

    assert Filtrex.Condition.param_key_type(@config, "completed_on_or_after") ==
             {:error, "Unknown filter key 'completed_on_or_after'"}

    assert Filtrex.Condition.param_key_type(@config, "date_column_contains") ==
             {:error, "Unknown filter key 'date_column_contains'"}
  end

  test "defaulting to certain comparator when none is present in params" do
    assert Filtrex.Condition.param_key_type(@config, "title") ==
             {:ok, Filtrex.Condition.Text, @text_config, "title", "equals"}
  end
end

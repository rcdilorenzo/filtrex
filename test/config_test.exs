defmodule FiltrexTypeConfigTest do
  use ExUnit.Case
  alias Filtrex.Type.Config

  @configs Filtrex.SampleModel.filtrex_config

  test "finding whether key is allowed" do
    refute Config.allowed?(@configs, "blah")
    assert Config.allowed?(@configs, "date_column")
  end

  test "finding the options for a specific key" do
    assert Config.options(@configs, "rating") == %{allowed_decimal: true}
    assert Config.options(@configs, "upvotes") == %{}
    assert Config.options(@configs, "blah") == %{}
  end

  test "finding the config for a specific key" do
    refute Config.config(@configs, "blah")
    assert Config.config(@configs, "title").type == :text
  end

  test "finding the configs for a specific type" do
    assert length(Config.configs_for_type(@configs, :number)) == 3
    assert Config.configs_for_type(@configs, :other) == []
  end
end

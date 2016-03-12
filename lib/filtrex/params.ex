defmodule Filtrex.Params do
  @moduledoc """
  `Filtrex.Params` is a module that parses parameters similar to Phoenix, such as:

  ```
  %{"due_date_between" => %{"start" => "2016-03-10", "end" => "2016-03-20"}, "text_column" => "Buy milk"}
  ```
  """

  @doc "Converts parameters to a list of conditions"
  def parse_conditions(configs, params) when is_map(params) do
    Enum.reduce(params, {:ok, []}, fn
      {key, value}, {:ok, conditions} ->
        convert_and_add_condition(configs, key, value, conditions)
      _, {:error, reason} ->
        {:error, reason}
    end)
  end

  defp convert_and_add_condition(configs, key, value, conditions) do
    case Filtrex.Condition.param_key_type(configs, key) do
      {:ok, module, config, column, comparator} ->
        attrs = %{inverse: false, column: column, comparator: comparator, value: value}
        parse_and_add_condition(config, module, convert_value_in_attrs(attrs), conditions)
      {:error, reason} -> {:error, reason}
    end
  end

  defp parse_and_add_condition(config, module, attrs, conditions) do
    case module.parse(config, attrs) do
      {:error, reason} -> {:error, reason}
      {:ok, condition} -> {:ok, conditions ++ [condition]}
    end
  end

  defp convert_value_in_attrs(attrs = %{value: value}) do
    Map.put(attrs, :value, convert_value(value))
  end

  defp convert_value(map) when is_map(map) do
    Enum.map(map, fn
      {key, value} when is_binary(key) ->
        {String.to_atom(key), value}
      {key, value} -> {key, value}
    end) |> Enum.into(%{})
  end
  defp convert_value(value), do: value
end

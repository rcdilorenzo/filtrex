defmodule Filtrex.Condition do
  @callback parse(Map.t, %{column: String.t, value: any, comparator: String.t}) :: {:ok, any} | {:error, any}

  defstruct column: nil, comparator: nil, value: nil

  def parse(config, options = %{type: type}) do
    try do
      module_type = type |> Mix.Utils.camelize
      module = Module.safe_concat(Filtrex.Condition, module_type)
      module.parse(
        config[String.to_existing_atom(type)],
        Map.delete(options, :type)
      )
    rescue ArgumentError ->
      {:error, ["Unknown filter condition '#{type}'"]}
    end
  end

  def validate_in(nil, _), do: nil
  def validate_in(_, nil), do: nil
  def validate_in(value, list) do
    cond do
      value in list -> value
      true -> nil
    end
  end

  def validate_is_binary(value) when is_binary(value), do: value
  def validate_is_binary(_), do: nil

  def parse_error(value, type, filter_type) do
    "Invalid #{to_string(filter_type)} #{to_string(type)} '#{value}'"
  end

  def parse_value_type_error(column, filter_type) do
    "Invalid #{to_string(filter_type)} value for #{column}"
  end
end

defprotocol Filtrex.Encoder do
  @doc "Encodes a condition to SQL fragments"
  def encode(condition)
end

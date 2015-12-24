defmodule Filtrex.Condition do
  @moduledoc """
  `Filtrex.Condition` is an abstract module for parsing conditions.
  """

  @callback parse(Map.t, %{inverse: boolean, column: String.t, value: any, comparator: String.t}) :: {:ok, any} | {:error, any}

  defstruct column: nil, comparator: nil, value: nil

  @doc """
  Parses a condition by dynamically delegating to modules
  
  It delegates based on the type field of the options map (e.g. `Filtrex.Condition.Text` for the type `"text"`).
  Example Input:
  config:
  ```
  Filtrex.Condition.parse(%{
    text: %{keys: ~w(title comments)}  # passed to the specific condition
  }, %{
    type: string,                      # converted to Filtrex.Condition."__" dynamically
    column: string,
    comparator: string,
    value: string,
    inverse: boolean                   # inverts the comparator logic
  })
  ```
  """
  def parse(config, options = %{type: type, inverse: inverse}) do
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

  @doc "Helper method to validate whether a value is in a list"
  @spec validate_in(any, List.t) :: nil | any
  def validate_in(nil, _), do: nil
  def validate_in(_, nil), do: nil
  def validate_in(value, list) do
    cond do
      value in list -> value
      true -> nil
    end
  end

  @doc "Helper method to validate whether a value is a binary"
  @spec validate_is_binary(any) :: nil | String.t
  def validate_is_binary(value) when is_binary(value), do: value
  def validate_is_binary(_), do: nil

  @doc "Generates an error description for a generic parse error"
  @spec parse_error(any, Atom.t, Atom.t) :: String.t
  def parse_error(value, type, filter_type) do
    "Invalid #{to_string(filter_type)} #{to_string(type)} '#{value}'"
  end

  @doc "Generates an error description for a parse error resulting from an invalid value type"
  @spec parse_value_type_error(String.t, Atom.t) :: String.t
  def parse_value_type_error(column, filter_type) do
    "Invalid #{to_string(filter_type)} value for #{column}"
  end
end

defprotocol Filtrex.Encoder do
  @moduledoc """
  Encodes a condition into `Filtrex.Fragment` as an expression with values

  Example:
  ```
  defimpl Filtrex.Encoder, for: Filtrex.Condition.Text do
    def encode(%Filtrex.Condition.Text{column: column, comparator: "is", value: value}) do
      %Filtrex.Fragment{expression: "\#\{column\} = ?", values: [value]}
    end
  end
  ```
  """

  @spec encode(Filter.Condition.t) :: [String.t | [any]]
  def encode(condition)
end

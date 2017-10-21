defmodule Filtrex.Condition do
  @moduledoc """
  `Filtrex.Condition` is an abstract module for parsing conditions.
  To implement your own condition, add `use Filtrex.Condition` in your module and implement the three callbacks:

    * `parse/2` - produce a condition struct from a configuration and attributes
    * `type/0` - the description of the condition that must match the underscore version of the module's last namespace
    * `comparators/0` - the list of used query comparators for parsing params
  """
  @modules [
    Filtrex.Condition.Text,
    Filtrex.Condition.Date,
    Filtrex.Condition.DateTime,
    Filtrex.Condition.Boolean,
    Filtrex.Condition.Number
  ]

  @callback parse(Filtrex.Type.Config.t, %{inverse: boolean, column: String.t, value: any, comparator: String.t}) :: {:ok, any} | {:error, any}
  @callback type :: Atom.t
  @callback comparators :: [String.t]

  defstruct column: nil, comparator: nil, value: nil

  defmacro __using__(_) do
    quote do
      import Filtrex.Utils.Encoder
      alias Filtrex.Condition
      import unquote(__MODULE__), except: [parse: 2]
      @behaviour Filtrex.Condition

      defstruct type: nil, column: nil, comparator: nil, value: nil, inverse: false
    end
  end

  @doc """
  Parses a condition by dynamically delegating to modules

  It delegates based on the type field of the options map (e.g. `Filtrex.Condition.Text` for the type `"text"`).
  Example Input:
  config:
  ```
  Filtrex.Condition.parse([
    %Filtrex.Type.Config{type: :text, keys: ~w(title comments)}
  ], %{
    type: string,
    column: string,
    comparator: string,
    value: string,
    inverse: boolean                   # inverts the comparator logic
  })
  ```
  """
  def parse(configs, options = %{type: type}) do
    case condition_module(type) do
      nil ->
        {:error, "Unknown filter condition '#{type}'"}
      module ->
        type_atom = String.to_existing_atom(type)
        config = Filtrex.Type.Config.configs_for_type(configs, type_atom)
          |> Filtrex.Type.Config.config(options[:column])
        if config do
          module.parse(config, Map.delete(options, :type))
        else
          {:error, "Unknown column '#{options[:column]}'"}
        end
    end
  end

  @doc "Parses a params key into the condition type, column, and comparator"
  def param_key_type(configs, key_with_comparator) do
    result = Enum.find_value(condition_modules(), fn (module) ->
      Enum.find_value(module.comparators, fn (comparator) ->
        normalized = "_" <> String.replace(comparator, " ", "_")
        key = String.replace_trailing(key_with_comparator, normalized, "")
        config = Filtrex.Type.Config.config(configs, key)
        if !is_nil(config) and key in config.keys and config.type == module.type do
          {:ok, module, config, key, comparator}
        end
      end)
    end)
    if result, do: result, else: {:error, "Unknown filter key '#{key_with_comparator}'"}
  end

  @doc "Helper method to validate that a comparator is in list"
  @spec validate_comparator(atom, binary, List.t) :: {:ok, binary} | {:error, binary}
  def validate_comparator(type, comparator, comparators) do
    if comparator in comparators do
      {:ok, comparator}
    else
      {:error, parse_error(comparator, :comparator, type)}
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
  @spec parse_value_type_error(any, Atom.t) :: String.t
  def parse_value_type_error(column, filter_type) when is_binary(column) do
    "Invalid #{to_string(filter_type)} value for #{column}"
  end
  def parse_value_type_error(column, filter_type) do
    opts   = struct(Inspect.Opts, [])
    iodata = Inspect.Algebra.to_doc(column, opts)
      |> Inspect.Algebra.format(opts.width)
      |> Enum.join

    if String.length(iodata) <= 15 do
      parse_value_type_error("'#{iodata}'", filter_type)
    else
      "'#{String.slice(iodata, 0..12)}...#{String.slice(iodata, -3..-1)}'"
        |> parse_value_type_error(filter_type)
    end
  end

  @doc "List out the available condition modules"
  def condition_modules do
    Application.get_env(:filtrex, :conditions, @modules)
  end

  defp condition_module(type) do
    Enum.find(condition_modules(), fn (module) ->
      type == to_string(module.type)
    end)
  end
end

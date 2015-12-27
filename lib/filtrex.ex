defmodule Filtrex do
  @moduledoc """
  Filtrex consists of three primary components:

    * `Filtrex` - handles the overall parsing of filters and delegates to
      `Filtrex.AST` to build an ecto query expression

    * `Filtrex.Condition` - an abstract module built to delegate to specific condition modules in the format of `Filtrex.Condition.Type` where the type is converted to CamelCase (See `Filtrex.Condition.Text.parse/2`)

    * `Filtrex.Fragment` - simple struct to hold generated expressions and values to be used when generating queries for ecto
  """

  defstruct type: nil, conditions: [], sub_filters: []

  @type t :: Filtrex.t

  @doc """
  Parses a filter expression and returns errors or the parsed filter with
  the appropriate parsed sub-structures.

  The `config` option is a map of the acceptable types and the configuration
  options to pass to each condition type.
  Example:
  ```
  %{
    text: %{keys: ~w(title comments)}
  }
  ```
  """
  @spec parse(Map.t, Map.t) :: {:errors, List.t} | {:ok, Filtrex.t}
  def parse(_, %{filter: %{type: type}}) when not type in ~w(all any none) do
    {:errors, ["Invalid filter type #{type}"]}
  end

  def parse(_, %{filter: %{conditions: []}}) do
    {:errors, ["One or more conditions required to filter"]}
  end

  def parse(config, %{filter: %{type: type, conditions: conditions, sub_filters: sub_filters}}) when is_list(conditions) do
    parsed_filters = Enum.reduce_while sub_filters, [], fn (to_parse, acc) ->
      case parse(config, to_parse) do
        {:ok, filter} -> {:cont, acc ++ [filter]}
        {:errors, errors} -> {:halt, {:errors, errors}}
      end
    end
    case parsed_filters do
      {:errors, _} -> parsed_filters
      _ -> parse_conditions(config, type, conditions)
             |> parse_condition_results(type, parsed_filters)
    end
  end

  def parse(config, %{filter: %{type: type, conditions: conditions}}) when is_list(conditions) do
    parse(config, %{filter: %{type: type, conditions: conditions, sub_filters: []}})
  end

  def parse(_, _), do: {:error, "Invalid filter structure"}

  defp parse_conditions(config, type, conditions) do
    Enum.reduce(conditions, %{errors: [], conditions: []}, fn (map, acc) ->
      case Filtrex.Condition.parse(config, Map.put(map, :inverse, inverse_for(type))) do
        {:error, error} ->
          update_list_in_map(acc, :errors, error)
        {:ok, condition} ->
          update_list_in_map(acc, :conditions, condition)
      end
    end)
  end

  defp parse_condition_results(%{errors: [], conditions: conditions}, type, parsed_filters) do
    {:ok, %Filtrex{type: type, conditions: conditions, sub_filters: parsed_filters}}
  end
  defp parse_condition_results(%{errors: errors, conditions: []}, _, _) do
    {:errors, errors}
  end


  @doc """
  Converts a filter with the specified ecto module name into a valid ecto query
  expression that is compiled when called.
  """
  @spec query(Filter.t, module, Macro.Env.t) :: Ecto.Query.t
  def query(filter, model, env) do
    Filtrex.AST.build_query(filter, model)
      |> Code.eval_quoted([], env)
      |> elem(0)
  end

  defp inverse_for("none"), do: true
  defp inverse_for(_),      do: false

  defp update_list_in_map(map, key, value) do
    values = Map.get(map, key)
    Map.put(map, key, values ++ [value])
  end
end

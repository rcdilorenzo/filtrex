defmodule Filtrex do
  @moduledoc """
  Filtrex consists of the following primary components:

    * `Filtrex` - handles the overall parsing of filters and delegates to
      `Filtrex.AST` to build an ecto query expression

    * `Filtrex.Condition` - an abstract module built to delegate to specific condition modules in the format of `Filtrex.Condition.Type` where the type is converted to CamelCase (See `Filtrex.Condition.Text.parse/2`)

    * `Filtrex.Params` - an abstract module for parsing plug-like params from a query string into a filter

    * `Filtrex.Fragment` - simple struct to hold generated expressions and values to be used when generating queries for ecto

    * `Filtrex.Type.Config` - struct to hold various configuration and validation options for creating a filter
  """

  defstruct type: nil, conditions: [], sub_filters: []

  @whitelist [
    :filter, :type, :conditions, :sub_filters,
    :column, :comparator, :value, :start, :end
  ]

  @type t :: Filtrex.t

  @doc """
  Parses a filter expression and returns errors or the parsed filter with
  the appropriate parsed sub-structures.

  The `configs` option is a list of type configs (See `Filtrex.Type.Config`)
  Example:
  ```
  [%Filtrex.Type.Config{type: :text, keys: ~w(title comments)}]
  ```
  """
  @spec parse([Filtrex.Type.Config.t], Map.t) :: {:errors, List.t} | {:ok, Filtrex.t}
  def parse(_, %{filter: %{type: type}}) when not type in ~w(all any none) do
    {:errors, ["Invalid filter type #{type}"]}
  end

  def parse(_, %{filter: %{conditions: []}}) do
    {:errors, ["One or more conditions required to filter"]}
  end

  def parse(configs, %{filter: %{type: type, conditions: conditions, sub_filters: sub_filters}}) when is_list(conditions) do
    parsed_filters = Enum.reduce_while sub_filters, [], fn (to_parse, acc) ->
      case parse(configs, to_parse) do
        {:ok, filter} -> {:cont, acc ++ [filter]}
        {:errors, errors} -> {:halt, {:errors, errors}}
      end
    end
    case parsed_filters do
      {:errors, _} -> parsed_filters
      _ -> parse_conditions(configs, type, conditions)
             |> parse_condition_results(type, parsed_filters)
    end
  end

  def parse(configs, %{filter: %{type: type, conditions: conditions}}) when is_list(conditions) do
    parse(configs, %{filter: %{type: type, conditions: conditions, sub_filters: []}})
  end

  def parse(configs, map) when is_map(map) do
    with {:ok, sanitized} <- Filtrex.Params.sanitize(map, @whitelist),
      do: parse(configs, sanitized)
  end

  def parse(_, _), do: {:error, "Invalid filter structure"}

  defp parse_conditions(configs, type, conditions) do
    Enum.reduce(conditions, %{errors: [], conditions: []}, fn (map, acc) ->
      case Filtrex.Condition.parse(configs, Map.put(map, :inverse, inverse_for(type))) do
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
  defp parse_condition_results(%{errors: errors}, _, _) do
    {:errors, errors}
  end

  @doc """
  This function converts Plug-decoded params like the example below into a filtrex struct based on options in the configs.
  ```
  %{"comments_contains" => "love",
    "title" => "My Blog Post",
    "created_at_between" => %{"start" => "2014-01-01", "end" => "2016-01-01"}}
  ```
  """
  def parse_params(configs, params) do
    with {:ok, {type, params}} <- parse_params_filter_union(params),
         {:ok, conditions} <- Filtrex.Params.parse_conditions(configs, params),
         do: {:ok, %Filtrex{type: type, conditions: conditions}}
  end

  @doc """
  Converts a filter with the specified ecto module name into a valid ecto query
  expression that is compiled when called.
  """
  @spec query(Filter.t, module) :: Ecto.Query.t
  defmacro query(filter, model) do
    quote do
      Filtrex.AST.build_query(unquote(filter), unquote(model))
        |> Code.eval_quoted([], __ENV__)
        |> elem(0)
    end
  end

  defp parse_params_filter_union(params) do
    case Map.fetch(params, "filter_union") do
      {:ok, type} when type in ~w(all any none) ->
        {:ok, {type, Map.delete(params, "filter_union")}}
      _ ->
        {:error, "Invalid filter union"}
    end
  end

  defp inverse_for("none"), do: true
  defp inverse_for(_),      do: false

  defp update_list_in_map(map, key, value) do
    values = Map.get(map, key)
    Map.put(map, key, values ++ [value])
  end
end

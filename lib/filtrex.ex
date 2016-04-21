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

  require Ecto.Query

  defstruct type: nil, conditions: [], sub_filters: [], empty: false

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
  def parse(configs, map) do
    with {:ok, sanitized} <- Filtrex.Params.sanitize(map, @whitelist),
         {:ok, valid_structured_map} <- validate_structure(sanitized),
      do: parse_validated_structure(configs, valid_structured_map)
  end

  @doc """
  This function converts Plug-decoded params like the example below into a filtrex struct based on options in the configs.
  ```
  %{"comments_contains" => "love",
    "title" => "My Blog Post",
    "created_at_between" => %{"start" => "2014-01-01", "end" => "2016-01-01"}}
  ```
  """
  def parse_params(configs, params) when params == %{}, do: {:ok, %Filtrex{empty: true}}
  def parse_params(configs, params) do
    with {:ok, {type, params}} <- parse_params_filter_union(params),
         {:ok, conditions} <- Filtrex.Params.parse_conditions(configs, params),
         do: {:ok, %Filtrex{type: type, conditions: conditions}}
  end

  @doc """
  Converts a filter with the specified ecto module name into a valid ecto query
  expression that is compiled when called.
  """
  @spec query(Ecto.Query.t, Filtrex.t) :: Ecto.Query.t
  def query(query, %Filtrex{empty: true}), do: query

  def query(query, filter) do
    {result, _} = Filtrex.AST.build_query(query, filter)
      |> Code.eval_quoted([], __ENV__)
    result
  end

  @doc """
  Validates the rough filter params structure
  """
  def validate_structure(map) do
    case map do
      %{filter: %{type: type}} when not type in ~w(all any none) ->
        {:errors, ["Invalid filter type '#{type}'"]}
      %{filter: %{conditions: conditions}} when conditions == [] or not is_list(conditions) ->
        {:errors, ["One or more conditions required to filter"]}
      %{filter: %{sub_filters: sub_filters}} when not is_list(sub_filters) ->
        {:errors, ["Sub-filters must be a valid list of filters"]}
      validated = %{filter: params} ->
        sub_filters = Map.get(params, :sub_filters, [])
        result = Enum.reduce_while(sub_filters, {:ok, []}, fn (sub_map, {:ok, acc}) ->
          case validate_structure(sub_map) do
            {:errors, errors} -> {:halt, {:errors, errors}}
            {:ok, sub_validated} -> {:cont, {:ok, acc ++ [sub_validated]}}
          end
        end)
        with {:ok, validated_sub_filters} <- result,
          do: {:ok, put_in(validated.filter[:sub_filters], validated_sub_filters)}
      _ ->
        {:errors, ["Invalid filter structure"]}
    end
  end

  defp parse_validated_structure(configs, %{filter: params}) do
    parsed_filters = Enum.reduce_while(params[:sub_filters], {:ok, []}, fn (to_parse, {:ok, acc}) ->
      case parse(configs, to_parse) do
        {:ok, filter} -> {:cont, {:ok, acc ++ [filter]}}
        {:errors, errors} -> {:halt, {:errors, errors}}
      end
    end)
    with {:ok, filters} <- parsed_filters,
      do: parse_conditions(configs, params[:type], params[:conditions])
       |> parse_condition_results(params[:type], filters)
  end

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

  defp parse_params_filter_union(params) do
    case Map.fetch(params, "filter_union") do
      {:ok, type} when type in ~w(all any none) ->
        {:ok, {type, Map.delete(params, "filter_union")}}
      :error ->
        {:ok, {"all", params}}
      _ ->
        {:errors, ["Invalid filter union"]}
    end
  end

  defp inverse_for("none"), do: true
  defp inverse_for(_),      do: false

  defp update_list_in_map(map, key, value) do
    values = Map.get(map, key)
    Map.put(map, key, values ++ [value])
  end
end

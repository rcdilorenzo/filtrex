defmodule Filtrex do
  defstruct type: nil, conditions: []

  @types ~w(all any none)

  def parse(_, %{filter: %{type: type}}) when not type in @types do
    {:errors, ["Invalid filter type #{type}"]}
  end

  def parse(_, %{filter: %{conditions: []}}) do
    {:errors, ["One or more conditions required to filter"]}
  end

  def parse(config, %{filter: %{type: type, conditions: conditions}}) when is_list(conditions) do
    results = Enum.reduce(conditions, %{errors: [], conditions: []}, fn (map, acc) ->
      case Filtrex.Condition.parse(config, Map.put(map, :inverse, inverse_for(type))) do
        {:error, error} ->
          update_list_in_map(acc, :errors, error)
        {:ok, condition} ->
          update_list_in_map(acc, :conditions, condition)
      end
    end)
    case results do
      %{errors: [], conditions: conditions} ->
        {:ok, %Filtrex{type: type, conditions: conditions}}
      %{errors: errors, conditions: []} ->
        {:errors, errors}
    end
  end

  def parse(_, _), do: {:error, "Invalid filter structure"}

  def query(filter, model, env) do
    Filtrex.AST.build_query(filter.conditions, model, logical_join(filter.type))
      |> Code.eval_quoted([], env)
      |> elem(0)
  end

  defp logical_join("any"), do: "OR"
  defp logical_join(_),     do: "AND"

  def inverse_for("none"), do: true
  def inverse_for(_),      do: false

  defp update_list_in_map(map, key, value) do
    values = Map.get(map, key)
    Map.put(map, key, values ++ [value])
  end
end

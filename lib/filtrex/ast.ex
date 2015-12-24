defmodule Filtrex.AST do

  @doc "Builds a 'from' ecto query from conditions and a join operator (e.g. 'AND')"
  def build_query(conditions, model, join) do
    fragments = Enum.map(conditions, &Filtrex.Encoder.encode/1)
    combined = {:from, [], [{:in, [context: Elixir, import: Kernel],
       [{:s, [], Elixir}, {:__aliases__, [alias: false], model(model)}]},
      [where: fragments(fragments, join)]]}
  end

  defp model(model) do
    [_ | rest] = to_string(model)
      |> String.split(".")
    rest |> Enum.map(&String.to_atom/1)
  end

  defp fragments(fragments, join) do
    expression = Enum.reduce fragments, ["" | []], fn
      (%Filtrex.Fragment{expression: new_expression, values: new_values}, ["" | values]) ->
        ["(#{new_expression})" | values ++ new_values]

      (%Filtrex.Fragment{expression: new_expression, values: new_values}, [expression | values]) ->
        combined = "#{expression} #{join} (#{new_expression})"
        [combined | values ++ new_values]
    end
    {:fragment, [], expression}
  end


end

defmodule Filtrex.AST do
  @moduledoc """
  `Filtrex.AST` is a helper for building out the ecto macro query expression
  from a set of conditions. Typically, it shouldn't need to be called direcly.
  """

  @doc "Builds a 'from' ecto query from conditions and a join operator (e.g. 'AND')"
  def build_query(query, filter) do
    query = Macro.escape(query)
    fragments = {:fragment, [], build_fragments(filter)}
    quote do: Ecto.Query.where(unquote(query), [s], unquote(fragments))
  end

  defp build_fragments(filter) do
    join = logical_join(filter.type)
    Enum.map(filter.conditions, &Filtrex.Encoder.encode/1)
      |> fragments(join)
      |> build_sub_fragments(join, filter.sub_filters)
  end

  defp build_sub_fragments(fragments, _, []), do: fragments
  defp build_sub_fragments(fragments, join, sub_filters) do
    Enum.reduce(sub_filters, fragments, fn (sub_filter, [expression | values]) ->
      [sub_expression | sub_values] = build_fragments(sub_filter)
      [join(expression, sub_expression, join) | values ++ sub_values]
    end)
  end

  defp join(expression1, expression2, join) do
    "(#{expression1}) #{join} (#{expression2})"
  end

  defp fragments(fragments, join) do
    Enum.reduce(fragments, ["" | []], fn
      (%{expression: new_expression, values: new_values}, ["" | values]) ->
        ["(#{new_expression})" | values ++ new_values]
      (%{expression: new_expression, values: new_values}, [expression | values]) ->
        combined = "#{expression} #{join} (#{new_expression})"
        [combined | values ++ new_values]
    end)
  end

  defp logical_join("any"), do: "OR"
  defp logical_join(_),     do: "AND"
end

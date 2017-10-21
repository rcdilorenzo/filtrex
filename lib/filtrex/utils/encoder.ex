defmodule Filtrex.Utils.Encoder do
  @moduledoc """
  Helper methods for implementing the `Filtrex.Encoder` protocol.
  """

  @doc """
  This macro allows a simple creation of encoders using a simple DSL.

  Example:
  ```
  encoder "equals", "does not equal", "column = ?", &(&1)
  ```

  In this example, a comparator and its reverse are passed in followed
  by an expression where "column" is substituted for the actual column
  name from the struct. The final argument is a function (which is not
  necessary in this case since it is the default value) that takes the
  raw value being passed in and returns the transformed value to be
  injected as a value into the fragment expression.
  """
  defmacro encoder(comparator, reverse_comparator, expression, values_function \\ {:&, [], [[{:&, [], [1]}]]}) do
    quote do
      import Filtrex.Utils.Encoder

      def encode(condition = %{comparator: unquote(comparator), inverse: true}) do
        condition |> struct(inverse: false, comparator: unquote(reverse_comparator)) |> encode
      end

      def encode(%{column: column, comparator: unquote(comparator), value: value}) do
        values = 
          unquote(values_function).(value)
          |> intersperse_column_refs(column)

        %Filtrex.Fragment{
          expression: String.replace(unquote(expression), "column", "?"),
          values: values
        }
      end
    end
  end

  @doc """
  Intersperses proper Ecto column references between values to be 
  queried.

  ## Examples

      intersperse_column_refs(["post"], "title")
      # => [s.title, "post"]
      
      intersperse_column_refs(["best", "post"], "title")
      # => [s.title, "best", s.title, "post"]

  ## Background
  
  Ecto queries support string query fragments, but fields referenced in
  these fragments need to specifically reference fields, or you will get 
  "Ambiguous column" errors for some queries.

  In other words:

      # Good
      where(query, [s], fragment("lower(?) = lower(?)", s.title, "post")

      # Bad
      where(query, [s], fragment("lower(title) = lower(?)", "post"))

  Interpolating `s.title` into the fragment arguments ensures that joined
  tables which also have the `title` column will not conflict.

  See `Ecto.Query.API.fragment/1` for more details.
  """
  def intersperse_column_refs(values, column) do
    column = String.to_existing_atom(column)

    [quote do: s.unquote(column)]
    |> Stream.cycle
    |> Enum.take(length(values))
    |> Enum.zip(values)
    |> Enum.map(&Tuple.to_list/1)
    |> List.flatten
  end
end

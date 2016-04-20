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
      def encode(condition = %{comparator: unquote(comparator), inverse: true}) do
        condition |> struct(inverse: false, comparator: unquote(reverse_comparator)) |> encode
      end

      def encode(%{column: column, comparator: unquote(comparator), value: value}) do
        %Filtrex.Fragment{
          expression: String.replace(unquote(expression), "column", column),
          values: unquote(values_function).(value)
        }
      end
    end
  end

end

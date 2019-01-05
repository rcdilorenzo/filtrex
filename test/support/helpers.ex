defmodule Filtrex.TestHelpers do
  @moduledoc """
  Functions that are useful in tests.
  """

  @doc """
  Returns a quoted reference to a column in a query, such as `s.title`.
  """
  def column_ref(column) do
    quote [context: Filtrex.Utils.FragmentEncoderDSL] do
      s.unquote(column)
    end
  end
end

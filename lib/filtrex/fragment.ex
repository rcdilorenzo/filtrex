defmodule Filtrex.Fragment do
  @moduledoc """
  `Filtrex.Fragment` is a simple struct used to hold an `expression` and `values`.
  It is used by `Filtrex.Encoder.encode/1` to turn conditions into ecto queries.
  Example:
  ```
  %Filtrex.Fragment{expression: "(text = ?)", values: ["Buy Milk"]}
  ```
  """

  defstruct expression: nil, values: []
end

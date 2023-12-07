defmodule Filtrex.Condition.UUID do
  @moduledoc """
  Custom filter type for uuid columns. Supports "equals" and "contains" comparators.
  """

  use Filtrex.Condition

  @comparators ["equals", "does not equal", "contains", "does not contain"]

  @impl true
  def type, do: :uuid

  @impl true
  def comparators, do: @comparators

  @impl true
  def parse(_config, %{column: column, comparator: comparator, value: value, inverse: inverse}) do
    condition = %__MODULE__{
      type: :uuid,
      inverse: inverse,
      column: column,
      comparator: validate_in(comparator, @comparators),
      value: validate_is_binary(value)
    }

    case condition do
      %{comparator: nil} ->
        {:error, parse_error(comparator, :comparator, :uuid)}

      %{value: nil} ->
        {:error, parse_value_type_error(column, :uuid)}

      _ ->
        {:ok, condition}
    end
  end

  alias Filtrex.Type.Config

  defmacro uuid(keys, opts \\ [])

  defmacro uuid(keys, opts) when is_list(keys) do
    quote do
      var!(configs) =
        var!(configs) ++
          [
            %Filtrex.Type.Config{
              type: :uuid,
              keys: Config.to_strings(unquote(keys)),
              options: Enum.into(unquote(opts), %{})
            }
          ]
    end
  end

  defmacro uuid(key, opts) do
    quote do
      uuid([to_string(unquote(key))], unquote(opts))
    end
  end

  defimpl Filtrex.Encoder do
    encoder("equals", "does not equal", "text(column) = ?")
    encoder("does not equal", "equals", "text(column) != ?")

    encoder("contains", "does not contain", "text(column) ILIKE ?", &["%#{&1}%"])
    encoder("does not contain", "contains", "text(column) NOT ILIKE ?", &["%#{&1}%"])
  end
end

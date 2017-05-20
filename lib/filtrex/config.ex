defmodule Filtrex.Type.Config do
  @moduledoc """
  This configuration struct is for passing options at the top-level (e.g. `Filtrex.parse/2`) in a list. See `defconfig/1` for a more specific example.

  Struct keys:
    * `type`: the corresponding condition module with this type (e.g. :text = Filtrex.Condition.Text)
    * `keys`: the allowed keys for this configuration
    * `options`: the configuration options to be passed to the condition
  """

  @type t :: Filtrex.Type.Config

  defstruct type: nil, keys: [], options: %{}

  @doc "Returns whether the passed key is listed in any of the configurations"
  def allowed?(configs, key) do
    Enum.any?(configs, &(key in &1.keys))
  end

  @doc "Returns the configuration for the specified key"
  def config(configs, key) do
    List.first(for c <- configs, key in c.keys, do: c)
  end

  @doc "Narrows the list of configurations to only the specified type"
  def configs_for_type(configs, type) do
    for c <- configs, c.type == type, do: c
  end

  @doc "Returns the specific options of a configuration based on the key"
  def options(configs, key) do
    (config(configs, key) || struct(__MODULE__)).options
  end

  @doc """
  Allows easy creation of a configuration list:

      iex> import Filtrex.Type.Config
      iex>
      iex> defconfig do
      iex>   # Single key can be passed
      iex>   number :rating, allow_decimal: true
      iex>
      iex>   # Multiple keys
      iex>   text [:title, :description]
      iex>
      iex>   # String key can be passed
      iex>   date "posted", format: "{ISOz}"
      iex> end
      [
        %Filtrex.Type.Config{keys: ["rating"], options: %{allow_decimal: true}, type: :number},
        %Filtrex.Type.Config{keys: ["title", "description"], options: %{}, type: :text},
        %Filtrex.Type.Config{keys: ["posted"], options: %{format: "{ISOz}"}, type: :date}
      ]
  """
  defmacro defconfig(block) do
    quote do
      var!(configs) = []
      unquote(block)
      var!(configs)
    end
  end

  for module <- Filtrex.Condition.condition_modules do
    @doc "Generate a config struct for `#{to_string(module) |> String.slice(7..-1)}`"
    defmacro unquote(module.type)(key_or_keys, opts \\ [])
    defmacro unquote(module.type)(keys, opts) when is_list(keys) do
      type = unquote(module.type)
      quote do
        var!(configs) = var!(configs) ++
          [%Filtrex.Type.Config{type: unquote(type),
                                keys: Filtrex.Type.Config.to_strings(unquote(keys)),
                                options: Enum.into(unquote(opts), %{})}]
      end
    end

    defmacro unquote(module.type)(key, opts) do
      type = unquote(module.type)
      quote do
        unquote(type)([to_string(unquote(key))], unquote(opts))
      end
    end
  end

  @doc "Convert a list of mixed atoms and/or strings to a list of strings"
  def to_strings(keys, strings \\ [])
  def to_strings([key | keys], strings) when is_atom(key) do
    to_strings(keys, strings ++ [to_string(key)])
  end
  def to_strings([key | keys], strings) when is_binary(key) do
    to_strings(keys, strings ++ [key])
  end
  def to_strings([], strings), do: strings
end

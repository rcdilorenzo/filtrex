defmodule Filtrex.Type.Config do
  @moduledoc """
  This configuration struct is for passing options at the top-level (e.g. `Filtrex.parse/2`) in a list.

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
end

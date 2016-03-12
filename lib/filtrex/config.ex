defmodule Filtrex.Type.Config do
  defstruct type: nil, keys: [], options: %{}

  def allowed?(configs, key) do
    Enum.any?(configs, &(key in &1.keys))
  end

  def config(configs, key) do
    List.first(for c <- configs, key in c.keys, do: c)
  end

  def configs_for_type(configs, type) do
    for c <- configs, c.type == type, do: c
  end

  def options(configs, key) do
    (config(configs, key) || struct(__MODULE__)).options
  end
end

defmodule Factory.FilterParams do
  use ExMachina

  def all_factory do
    %{filter: %{type: "all", conditions: []}}
  end

  def any_factory do
    %{filter: %{type: "any", conditions: []}}
  end

  def none_factory do
    %{filter: %{type: "none", conditions: []}}
  end

  def type(filter_params, type) do
    put_in(filter_params[:filter][:type], type)
  end

  def conditions(filter_params, conditions) do
    put_in(filter_params[:filter][:conditions], conditions)
  end

  def sub_filters(filter_params, filters) do
    put_in(filter_params[:filter][:sub_filters], filters)
  end
end

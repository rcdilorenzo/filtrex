defmodule Factory.ConditionParams do
  use ExMachina

  def text_factory do
    %{type: "text", column: "title", comparator: "equals", value: "earth"}
  end

  def date_factory do
    %{type: "date", column: "date_column", comparator: "equals", value: "2015-03-01"}
  end

  def datetime_factory do
    %{type: "datetime", column: "datetime_column", comparator: "equals", value: "2016-04-02T13:00:00.000Z"}
  end

  def number_rating_factory do
    %{type: "number", column: "rating", comparator: "equals", value: 0}
  end

  def number_upvotes_factory do
    %{type: "number", column: "upvotes", comparator: "equals", value: 0}
  end

  def value(condition, value) do
    Map.put(condition, :value, value)
  end

  def column(condition, column) do
    Map.put(condition, :column, column)
  end

  def comparator(condition, comparator) do
    Map.put(condition, :comparator, comparator)
  end

  def equals(condition),         do: comparator(condition, "equals")
  def does_not_equal(condition), do: comparator(condition, "does not equal")
  def on_or_after(condition),    do: comparator(condition, "on or after")
  def on_or_before(condition),   do: comparator(condition, "on or before")
end

defmodule Filtrex.Validator.Date do
  @intervals ~w(days weeks months years)
  @format "{YYYY}-{0M}-{0D}"
  @moduledoc false

  def format, do: @format

  def parse_string_date(value) when is_binary(value) do
    case parse_format(value) do
      {:ok, _} -> value
      {:error, error} -> error
    end
  end
  def parse_string_date(_), do: nil


  def parse_start_end(value = %{start: start, end: end_value}) do
    case {parse_format(start), parse_format(end_value)} do
      {{:ok, _}, {:ok, _}} -> value
      {{:error, error}, _} -> error
      {_, {:error, error}} -> error
    end
  end
  def parse_start_end(_), do: "Both a start and end key are required."

  def parse_relative(value = %{interval: interval, amount: amount}) do
    cond do
      !is_integer(amount) ->
        "Amount must be an integer value."
      not interval in @intervals ->
        "'#{interval}' is not a valid interval."
      true -> value
    end
  end
  def parse_relative(_), do: "Both an interval and amount key are required."

  defp parse_format(value) do
    Timex.DateFormat.parse(value, @format)
  end
end

defmodule Filtrex.Validator.Date do
  @format "{YYYY}-{0M}-{0D}"
  @moduledoc false

  alias Timex.Parse.DateTime.Parser, as: TimexParser
  import Filtrex.Condition, only: [parse_value_type_error: 2]

  def format, do: @format

  def parse_string_date(config, value) when is_binary(value) do
    parse_format(config, value)
  end
  def parse_string_date(config, value) do
    {:error, parse_value_type_error(value, config.type)}
  end


  def parse_start_end(config, %{start: start, end: end_value}) do
    case {parse_format(config, start), parse_format(config, end_value)} do
      {{:ok, start}, {:ok, end_value}} ->
        {:ok, %{start: start, end: end_value}}
      {{:error, error}, _} -> {:error, error}
      {_, {:error, error}} -> {:error, error}
    end
  end
  def parse_start_end(_, _) do
    {:error, wrap_specific_error("Both a start and end key are required.")}
  end

  defp wrap_specific_error(error) do
    "Invalid date value format: #{error}"
  end

  defp parse_format(config, value) do
    result = with {:ok, datetime} <- TimexParser.parse(value, config.options[:format] || @format),
                  {:ok, date}     <- Timex.to_date(datetime), do: date
    case result do
      {:error, error} -> {:error, wrap_specific_error(error)}
      date            -> {:ok, date}
    end
  end
end

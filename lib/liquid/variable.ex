defmodule Liquid.Variable do
  @moduledoc """
    Module to create and lookup for Variables

  """
  defstruct name: nil, literal: nil, filters: [], parts: []
  alias Liquid.{Filters, Variable, Context, ParserSwitching, Parser}

  @behaviour Parser

  @doc """
    resolves data from `Liquid.Variable.parse/1` and creates a variable struct
  """
  def create(markup) when is_binary(markup) do
    [name|filters] = markup |> parse
    name = name |> String.trim
    variable = %Liquid.Variable{name: name, filters: filters}
    parsed = Liquid.Appointer.parse_name(name)
    Map.merge(variable, parsed)
  end

  @doc """
  Assigns context to variable and than applies all filters
  """
  def lookup(%Variable{}=v, %Context{}=context) do
    { ret, filters } = Liquid.Appointer.assign(v, context)
    try do
      filters |> Filters.filter(ret) |> apply_global_filter(context)
    rescue
      e in UndefinedFunctionError -> e.reason
      e in ArgumentError -> e.message
      e in ArithmeticError -> "Liquid error: #{e.message}"
    end
  end

  defp apply_global_filter(input, %Context{global_filter: nil}) do
    input
  end

  defp apply_global_filter(input, %Context{}=context),
   do: input |> context.global_filter.()

  @doc """
  Parses the markup to a list of filters
  """
  def parse(markup) when is_binary(markup) do
    ParserSwitching.parse_with_selected_parser(markup, __MODULE__)
  end

  @doc """
  Implementation of lax Parser behaviour
  """
  def lax(markup) when is_binary(markup) do
    [name|filters] = if markup != "" do
      Liquid.filter_parser
        |> Regex.scan(markup)
        |> List.flatten
        |> Enum.filter(&(&1 != "|"))
        |> Enum.map(&String.trim/1)
      else
        [""]
      end
    filters = for markup <- filters do
      [_, filter] = ~r/\s*(\w+)/ |> Regex.scan(markup) |> hd
      args = Liquid.filter_arguments
        |> Regex.scan(markup)
        |> List.flatten
        |> Liquid.List.even_elements

      [String.to_atom(filter), args]
    end
    [name|filters]
  end

  @doc """
  Implementation of strict Parser behaviour
  """
  def strict(markup) when is_binary(markup) do
    # TODO: Implement strict parser
    lax(markup)
  end

end

defmodule JsonpathEx.Parser do
  @moduledoc """
  Defines parsers for JSONPath expressions using NimbleParsec.

  This module handles the parsing of JSONPath syntax, including filters, grouping,
  and the main JSONPath expression. The parsed output is structured and tagged
  for further processing.
  """

  require Logger
  import NimbleParsec
  alias JsonpathEx.Helpers

  @doc """
  Parses a JSONPath expression.

  Returns a tagged structure on success or an error tuple on failure.
  """
  defparsec(
    :jsonpath,
    Helpers.root()
    |> repeat(
      choice([
        Helpers.dot_child(),
        Helpers.array(),
        Helpers.bracket_child(),
        parsec(:filter_expression),
        Helpers.function(),
        Helpers.deep_scan(),
        Helpers.dot()
      ])
    ),
    export_metadata: true
  )

  @doc """
  Parses a filter expression (e.g., `[?(@.price < 10)]`).

  Filters use expressions and logical operators for conditional selection.
  """
  defparsec(
    :filter_expression,
    ignore(string("[?("))
    |> parsec(:expression)
    |> ignore(string(")]"))
    |> tag(:filter_expression),
    export_metadata: true
  )

  @doc """
  Parses a grouping expression, optionally negated.

  Grouping expressions allow logical combinations of conditions.
  """
  defparsec(
    :grouping,
    optional(Helpers.not_())
    |> ignore(Helpers.left_paren())
    |> parsec(:expression)
    |> ignore(Helpers.right_paren())
    |> tag(:grouping)
  )

  # Logical operand or grouping
  defcombinatorp(
    :operand,
    choice([
      optional(Helpers.not_()) |> concat(Helpers.operand()),
      parsec(:grouping)
    ])
  )

  # Term: operand followed by one or more operators and operands
  defcombinatorp(
    :term,
    parsec(:operand)
    |> repeat(Helpers.operators() |> parsec(:operand))
    |> tag(:term)
  )

  @doc """
  Parses an expression with logical and arithmetic operators.

  Expressions are composed of terms combined with operators.
  """
  defparsec(
    :expression,
    parsec(:term)
    |> repeat(Helpers.operators() |> parsec(:term))
  )

  @doc """
  Parses a JSONPath string and returns the parsed result or an error.

  ## Examples

      iex> JsonpathEx.Parser.parse("$.store.book[*].author")
      {:ok, [{:root, "$"}, {:dot_child, "store"}, ...]}

      iex> JsonpathEx.Parser.parse("invalid")
      {:error, "Incorrect value. Expected valid JSONPath expression."}
  """
  def parse(value) do
    case jsonpath(value) do
      {:ok, parsed_value, "", _, _, _} ->
        {:ok, parsed_value}

      {:ok, parsed_value, tail, _, _, _} ->
        Logger.warning("Could not parse value completely. Value: #{value}, tail: #{tail}")
        {:ok, parsed_value}

      {:error, message, value_tried, _, _, _} ->
        Logger.error("Could not parse value. Value: #{value_tried}, error: #{message}")
        {:error, "Incorrect value. #{message}"}
    end
  end
end

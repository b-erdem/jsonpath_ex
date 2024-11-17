defmodule JsonpathEx.Parser do
  require Logger

  import NimbleParsec

  alias JsonpathEx.Helpers

  defparsec(
    :filter_expression,
    ignore(string("[?("))
    |> parsec(:expression)
    |> ignore(string(")]"))
    |> tag(:filter_expression),
    export_metadata: true
  )

  defparsec(
    :grouping,
    optional(Helpers.not_())
    |> ignore(Helpers.left_paren())
    |> parsec(:expression)
    |> ignore(Helpers.right_paren())
    |> tag(:grouping)
  )

  defcombinatorp(
    :operand,
    choice([optional(Helpers.not_()) |> concat(Helpers.operand()), parsec(:grouping)])
  )

  defcombinatorp(
    :term,
    parsec(:operand)
    |> repeat(Helpers.all_operators() |> parsec(:operand))
    |> tag(:term)
  )

  defparsec(
    :expression,
    parsec(:term)
    |> repeat(Helpers.all_operators() |> parsec(:term))
  )

  # The main JsonPath expression
  defparsec(
    :jsonpath,
    Helpers.root()
    |> repeat(
      choice([
        Helpers.dot_child(),
        Helpers.array(),
        Helpers.bracket_child(),
        parsec(:filter_expression),
        # Placeholder, needs definition
        Helpers.function(),
        Helpers.deep_scan(),
        Helpers.dot()
      ])
    ),
    export_metadata: true
  )

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

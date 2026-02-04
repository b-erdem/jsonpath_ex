defmodule JSONPathEx do
  @moduledoc """
  Main interface for the JSONPathEx library.

  JSONPathEx provides tools to parse and evaluate JSONPath expressions
  against JSON data. This module serves as the main entry point, combining
  parsing and evaluation into a single, convenient function.

  ## Features

  - Parse JSONPath expressions into Abstract Syntax Trees (ASTs).
  - Evaluate JSONPath expressions or ASTs against JSON data.
  - Supports filters, recursive descent, array slicing, logical operators,
    arithmetic, `in`/`nin`, nested filters, shorthand filter syntax (`[?expr]`),
    escape sequences in quoted keys, quoted dot-child, and built-in functions.

  ## Examples

      iex> json_data = %{
      ...>   "store" => %{
      ...>     "book" => [
      ...>       %{
      ...>         "category" => "reference",
      ...>         "author" => "Nigel Rees",
      ...>         "title" => "Sayings of the Century",
      ...>         "price" => 8.95
      ...>       }
      ...>     ]
      ...>   }
      ...> }
      iex> JSONPathEx.evaluate("$.store.book[*].title", json_data)
      {:ok, ["Sayings of the Century"]}
  """

  alias JSONPathEx.{Parser, Evaluator}

  @doc """
  Parses and evaluates a JSONPath expression against the provided JSON data.

  Combines parsing and evaluation into a single step. Returns the result
  of the evaluation or an error tuple if parsing or evaluation fails.

  ## Parameters

    - `expression` (String): A valid JSONPath expression.
    - `json_data` (Map or List): The JSON data to query.

  ## Examples

      iex> json_data = %{
      ...>   "store" => %{
      ...>     "book" => [
      ...>       %{"title" => "Elixir in Action"},
      ...>       %{"title" => "Programming Elixir"}
      ...>     ]
      ...>   }
      ...> }
      iex> JSONPathEx.evaluate("$.store.book[*].title", json_data)
      {:ok, ["Elixir in Action", "Programming Elixir"]}

  ## Errors

      iex> JSONPathEx.evaluate("$.invalid[", %{})
      {:error, "Invalid JSONPath expression"}

  ## Notes

  - This function ensures that both parsing and evaluation are performed in sequence.
  - For debugging purposes, consider using `JSONPathEx.Parser` and `JSONPathEx.Evaluator` separately.
  """
  def evaluate(expression, json_data) do
    with {:ok, parsed} <- Parser.parse(expression) do
      {:ok, Evaluator.evaluate(parsed, json_data)}
    else
      error -> error
    end
  end

  @doc """
  Parses a JSONPath expression into an Abstract Syntax Tree (AST).

  This function is useful for debugging or when you want to inspect the structure
  of a JSONPath expression without evaluating it.

  ## Parameters

    - `expression` (String): A valid JSONPath expression.

  ## Examples

      iex> JSONPathEx.parse("$.store.book[*].title")
      {:ok, [root: "$", dot_child: ["store"], dot_child: ["book"], array: [array_wildcard: {:wildcard, "*"}], dot_child: ["title"]]}
  """
  def parse(expression) when is_binary(expression) do
    Parser.parse(expression)
  end
end

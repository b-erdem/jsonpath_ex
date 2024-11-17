defmodule JsonpathEx do
  @moduledoc """
  Main interface for JsonpathEx library.
  """

  alias JsonpathEx.{Parser, Evaluator}

  @doc """
  Parses and evaluates a JSONPath expression against JSON data.

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
      iex> JsonpathEx.evaluate("$.store.book[*].title", json_data)
      {:ok, ["Sayings of the Century"]}
  """
  def evaluate(expression, json_data) do
    with {:ok, parsed} <- Parser.parse(expression),
         result <- Evaluator.evaluate(parsed, json_data) do
      {:ok, result}
    else
      error -> error
    end
  end
end

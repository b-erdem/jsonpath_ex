# JSONPathEx

[![Elixir](https://img.shields.io/badge/elixir-~%3E%201.14-purple.svg)](https://elixir-lang.org/)  
A powerful and flexible Elixir library for parsing, evaluating, and navigating JSON data using [JSONPath](https://goessner.net/articles/JsonPath/).

---

## Features

- **JSONPath Parsing**: Robust support for JSONPath syntax, including recursive descent, filters, and array slicing.
- **JSONPath Evaluation**: Navigate and query JSON objects or arrays with ease.
- **Highly Configurable**: Modular design allows easy customization and extension.
- **Efficient Parsing**: Built on [`NimbleParsec`](https://hexdocs.pm/nimble_parsec), ensuring performance and flexibility.

---

## Installation

Add `jsonpath_ex` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:jsonpath_ex, "~> 0.1.0"}
  ]
end
```

Then run:

```bash
mix deps.get
```

## Usage

### Evaluating JSONPath Expressions

The `JSONPathEx` module provides a convenient evaluate/2 function to parse and evaluate a JSONPath expression in one step:

```elixir
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
```

### Parsing JSONPath Expressions

Use the `JSONPathEx.Parser` module to parse a JSONPath string into an Abstract Syntax Tree (AST):

```elixir
iex> JSONPathEx.Parser.parse("$.store.book[*].author")
{:ok, [{:root, "$"}, {:dot_child, "store"}, {:dot_child, "book"}, {:wildcard, "*"}, {:dot_child, "author"}]}
```

### Evaluating JSONPath Expressions

Use the `JSONPathEx.Evaluator` module to evaluate a JSONPath AST against JSON data:

```elixir
iex> ast = [{:root, "$"}, {:dot_child, "store"}, {:dot_child, "book"}, {:wildcard, "*"}, {:dot_child, "author"}]
iex> json = %{
...>   "store" => %{
...>     "book" => [
...>       %{"author" => "Author 1"},
...>       %{"author" => "Author 2"}
...>     ]
...>   }
...> }
iex> JSONPathEx.Evaluator.evaluate(ast, json)
["Author 1", "Author 2"]
```

### Evaluating JSONPath ASTs

Use the JSONPathEx.Evaluator module to evaluate a JSONPath AST against JSON data:

```elixir
iex> ast = [{:root, "$"}, {:dot_child, "store"}, {:dot_child, "book"}, {:wildcard, "*"}, {:dot_child, "author"}]
iex> json = %{
...>   "store" => %{
...>     "book" => [
...>       %{"author" => "Author 1"},
...>       %{"author" => "Author 2"}
...>     ]
...>   }
...> }
iex> JSONPathEx.Evaluator.evaluate(ast, json)
["Author 1", "Author 2"]
```

## Supported JSONPath Features

- **Root Selector** (`$`)
- **Current Context** (`@`)
- **Dot Notation** (`.key`)
- **Bracket Notation** (`['key']`)
- **Wildcard Selector** (`*`)
- **Recursive Descent** (`..`)
- **Array Slicing** (`[start:end:step]`)
- **Filters** (`[?(@.key < 10)]`)
- **Functions**: `length()`, `min()`, `max()`, `sum()`

## Roadmap

* Add support for additional functions (e.g., `avg()`, `concat()`).
* Expand the evaluator for custom user-defined functions.
* Improve performance for deeply nested JSON data.
* Add more examples and guides to the documentation.

## Contributing

Contributions are welcome! To contribute:

1. Fork the repository.
2. Create a feature branch: git checkout -b feature/my-feature.
3. Commit your changes: git commit -m "Add my feature".
4. Push to the branch: git push origin feature/my-feature.
5. Create a pull request.

Please ensure all tests pass before submitting your pull request:

```bash
mix test
```

## License

This project is licensed under the [MIT License](LICENSE).
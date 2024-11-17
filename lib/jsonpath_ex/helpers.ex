defmodule JsonpathEx.Helpers do
  import NimbleParsec

  # Basic parsers
  def root, do: string("$") |> tag(:root)
  def current, do: string("@") |> tag(:current)
  def wildcard, do: string("*") |> tag(:wildcard)
  def deep_scan, do: string("..") |> tag(:deep_scan)
  def dot, do: string(".") |> tag(:dot)
  def comma, do: string(",") |> tag(:comma)
  def colon, do: string(":") |> tag(:colon)
  def dot_wildcard, do: string(".*") |> tag(:dot_wildcard)
  def deep_scan_wildcard, do: string("..*") |> tag(:deep_scan_wildcard)
  def null, do: string("null") |> tag(:null)
  def single_quote, do: string("'") |> tag(:single_quote)
  def double_quote, do: string("\"") |> tag(:double_quote)

  def left_paren, do: string("(") |> tag(:left_paren)
  def right_paren, do: string(")") |> tag(:right_paren)

  def right_bracket, do: string("]") |> tag(:right_bracket)
  def left_bracket, do: string("[") |> tag(:left_bracket)

  def and_, do: string("&&") |> tag(:and)
  def or_, do: string("||") |> tag(:or)
  def not_, do: string("!") |> tag(:not)

  def true_, do: string("true") |> tag(true)
  def false_, do: string("false") |> tag(false)

  def boolean, do: choice([true_(), false_()]) |> tag(:boolean)

  def logical_operator,
    do: whitespace() |> choice([and_(), or_(), not_()]) |> whitespace()

  def eq, do: string("==") |> tag(:eq)
  def gt, do: string(">") |> tag(:gt)
  def lt, do: string("<") |> tag(:lt)
  def ge, do: string(">=") |> tag(:ge)
  def le, do: string("<=") |> tag(:le)
  def ne, do: string("!=") |> tag(:ne)
  def in_, do: string("in") |> tag(:in)
  def nin, do: string("nin") |> tag(:nin)
  def eq2, do: string("===") |> tag(:eq2)

  def compare_operator,
    do:
      whitespace()
      |> choice([eq2(), eq(), ge(), le(), gt(), lt(), ne(), in_(), nin(), eq2()])
      |> whitespace()

  def add, do: string("+") |> tag(:add)
  def sub, do: string("-") |> tag(:sub)
  def mul, do: string("*") |> tag(:mul)
  def div, do: string("/") |> tag(:div)
  def mod, do: string("%") |> tag(:mod)

  def arithmetic_operator,
    do:
      whitespace()
      |> choice([add(), sub(), mul(), div(), mod()])
      |> whitespace()

  def all_operators,
    do: choice([compare_operator(), logical_operator(), arithmetic_operator()]) |> tag(:operator)

  def length_, do: string("length()") |> tag(:length)
  def min_, do: string("min()") |> tag(:min)
  def max_, do: string("max()") |> tag(:max)
  def sum_, do: string("sum()") |> tag(:sum)

  def function, do: choice([length_(), min_(), max_(), sum_()]) |> tag(:function)

  def array_indices,
    do:
      numeric_index()
      |> repeat(ignore(comma()) |> concat(numeric_index()), min: 1)
      |> tag(:array_indices)

  def array_wildcard, do: wildcard() |> tag(:array_wildcard)

  def array_begin, do: numeric_index() |> tag(:begin)
  def array_end, do: numeric_index() |> tag(:end)
  def array_step, do: numeric_index() |> tag(:step)

  def array_slice,
    do:
      optional(array_begin())
      |> ignore(colon())
      |> optional(array_end())
      |> optional(ignore(colon()))
      |> optional(array_step())
      |> tag(:array_slice)

  def array,
    do:
      ignore(left_bracket())
      |> concat(choice([array_slice(), array_indices(), array_wildcard()]))
      |> ignore(right_bracket())
      |> tag(:array)

  def whitespace(combinator), do: concat(combinator, whitespace())
  def whitespace, do: ignore(optional(utf8_string([?\s], min: 0)))

  def single_quoted_string,
    do:
      ignore(single_quote())
      |> concat(utf8_string(all_chars(), min: 1))
      |> concat(ignore(single_quote()))

  def double_quoted_string,
    do:
      ignore(double_quote())
      |> concat(utf8_string(all_chars(), min: 1))
      |> concat(ignore(double_quote()))

  # Dot-notated child
  def dot_child,
    do:
      choice([
        dot()
        |> concat(utf8_string([?a..?z, ?A..?Z, ?0..?9, ?_, ?-], min: 1))
        |> lookahead_not(left_paren()),
        deep_scan()
        |> concat(utf8_string([?a..?z, ?A..?Z, ?0..?9, ?_, ?-], min: 1))
        |> lookahead_not(left_paren()),
        dot_wildcard(),
        deep_scan_wildcard()
      ])
      |> tag(:dot_child)

  # Bracket-notated child or children
  def bracket_child,
    do:
      ignore(left_bracket())
      |> concat(quoted_key())
      |> concat(repeat(ignore(comma()) |> concat(quoted_key())))
      |> ignore(right_bracket())
      |> tag(:bracket_child)

  def field_name do
    utf8_string([?a..?z, ?A..?Z, ?0..?9, ?_, ?., ?@, ?-], min: 1)
  end

  def quoted_field_name do
    choice([
      field_name(),
      between(ignore(string("'")), ignore(string("'")), field_name()),
      between(ignore(string("\"")), ignore(string("\"")), field_name())
    ])
    |> tag(:field_name)
  end

  def value do
    choice([
      numeric_index(),
      single_quoted_string(),
      double_quoted_string(),
      boolean(),
      null()
    ])
    |> tag(:value)
  end

  def list_value do
    between(
      left_bracket(),
      right_bracket(),
      value() |> repeat(comma() |> whitespace() |> concat(value()))
    )
    |> tag(:list_value)
  end

  # Quoted key (e.g., "keyName")
  def quoted_key, do: quoted_field_name()

  def operand do
    choice([
      current_context(),
      root_key(),
      list_value(),
      value()
    ])
    |> tag(:operand)
  end

  def current_context,
    do:
      current()
      |> concat(optional(json_field_path()))
      |> whitespace()
      |> tag(:current_context)

  def root_key, do: root() |> repeat(choice([dot_child(), bracket_child()])) |> tag(:root_key)

  def between(left, right, parser) do
    left
    |> concat(parser)
    |> concat(right)
  end

  def numeric_index do
    sign = optional(string("-"))

    digits = ascii_string([?0..?9], min: 1)

    sign
    |> concat(digits)
    |> reduce({__MODULE__, :to_integer, []})
  end

  def to_integer(x) do
    case x do
      [_sign, digits] -> -String.to_integer(digits)
      [digits] -> String.to_integer(digits)
    end
  end

  def json_field_path do
    repeat(
      choice([
        dot_child(),
        array(),
        bracket_child(),
        dot() |> concat(function())
      ])
    )
  end

  defp all_chars do
    [?a..?z, ?A..?Z, ?0..?9, ?_, ?[, ?], ?:, ?-, ?@, ?.]
  end
end

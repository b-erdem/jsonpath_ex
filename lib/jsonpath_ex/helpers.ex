defmodule JSONPathEx.Helpers do
  import NimbleParsec

  # Basic parsers
  def root, do: string("$") |> unwrap_and_tag(:root)
  def current, do: string("@") |> unwrap_and_tag(:current)
  def wildcard, do: string("*") |> unwrap_and_tag(:wildcard)
  def deep_scan, do: string("..") |> unwrap_and_tag(:deep_scan)
  def dot, do: string(".") |> unwrap_and_tag(:dot)
  def comma, do: string(",") |> unwrap_and_tag(:comma)
  def colon, do: string(":") |> unwrap_and_tag(:colon)
  def dot_wildcard, do: string(".*") |> unwrap_and_tag(:dot_wildcard)
  def deep_scan_wildcard, do: string("..*") |> unwrap_and_tag(:deep_scan_wildcard)
  def null, do: string("null") |> replace(nil)
  def single_quote, do: string("'") |> unwrap_and_tag(:single_quote)
  def double_quote, do: string("\"") |> unwrap_and_tag(:double_quote)

  def left_paren, do: string("(") |> unwrap_and_tag(:left_paren)
  def right_paren, do: string(")") |> unwrap_and_tag(:right_paren)

  def right_bracket, do: string("]") |> unwrap_and_tag(:right_bracket)
  def left_bracket, do: string("[") |> unwrap_and_tag(:left_bracket)

  def and_, do: string("&&") |> replace(:&&)
  def or_, do: string("||") |> replace(:||)
  def not_, do: string("!") |> replace(:!)

  def true_, do: string("true") |> replace(true)
  def false_, do: string("false") |> replace(false)

  # Raw true/false — no tag wrapper; value() will tag as {:value, true/false}
  def boolean, do: choice([true_(), false_()])

  def eq, do: string("==") |> replace(:==)
  def gt, do: string(">") |> replace(:>)
  def lt, do: string("<") |> replace(:<)
  def ge, do: string(">=") |> replace(:>=)
  def le, do: string("<=") |> replace(:<=)
  def ne, do: string("!=") |> replace(:!=)
  def in_, do: string("in") |> replace(:in)
  def nin, do: string("nin") |> replace(:"not in")
  def eq2, do: string("===") |> replace(:===)

  def add, do: string("+") |> replace(:+)
  def sub, do: string("-") |> replace(:-)
  def mul, do: string("*") |> replace(:*)
  def div, do: string("/") |> replace(:/)
  def mod, do: string("%") |> replace(:%)

  def ws_around(combinator), do: between(whitespace(), whitespace(), combinator)

  def comparison_operator,
    do: choice([eq2(), eq(), ge(), le(), gt(), lt(), ne(), in_(), nin()]) |> ws_around()

  def logical_operator, do: choice([and_(), or_(), not_()]) |> ws_around()

  def arithmetic_operator, do: choice([add(), sub(), mul(), div(), mod()]) |> ws_around()

  def operators,
    do:
      choice([comparison_operator(), logical_operator(), arithmetic_operator()])
      |> unwrap_and_tag(:operator)

  def length_, do: string("length()") |> replace(:length)
  def min_, do: string("min()") |> replace(:min)
  def max_, do: string("max()") |> replace(:max)
  def sum_, do: string("sum()") |> replace(:sum)
  def avg_, do: string("avg()") |> replace(:avg)
  def concat_, do: string("concat()") |> replace(:concat)

  def function,
    do:
      ignore(dot())
      |> choice([length_(), min_(), max_(), sum_(), avg_(), concat_()])
      |> unwrap_and_tag(:function)

  # Whitespace-tolerant array indices: $[ 0 , 1 ]
  def array_indices,
    do:
      whitespace()
      |> concat(numeric_index())
      |> repeat(whitespace() |> ignore(comma()) |> whitespace() |> concat(numeric_index()), min: 1)
      |> whitespace()
      |> tag(:array_indices)

  def array_wildcard, do: wildcard() |> unwrap_and_tag(:array_wildcard)

  def array_begin, do: numeric_index() |> unwrap_and_tag(:begin)
  def array_end, do: numeric_index() |> unwrap_and_tag(:end)
  def array_step, do: numeric_index() |> unwrap_and_tag(:step)

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
      |> choice([array_slice(), array_indices(), array_wildcard()])
      |> ignore(right_bracket())
      |> tag(:array)

  def whitespace(combinator), do: concat(combinator, whitespace())
  def whitespace, do: ignore(optional(utf8_string([?\s], min: 0)))

  # Single-quoted string with escape support: \' and \\
  def single_quoted_string,
    do:
      ignore(single_quote())
      |> repeat(
        choice([
          string("\\'") |> replace("'"),
          string("\\\\") |> replace("\\"),
          utf8_string([0..0x26, 0x28..0x5B, 0x5D..0x10FFFF], min: 1)
        ])
      )
      |> ignore(single_quote())
      |> reduce({__MODULE__, :join_strings, []})

  # Double-quoted string with escape support: \" and \\
  def double_quoted_string,
    do:
      ignore(double_quote())
      |> repeat(
        choice([
          string("\\\"") |> replace("\""),
          string("\\\\") |> replace("\\"),
          utf8_string([0..0x21, 0x23..0x5B, 0x5D..0x10FFFF], min: 1)
        ])
      )
      |> ignore(double_quote())
      |> reduce({__MODULE__, :join_strings, []})

  # Dot-notated child (plain, quoted, wildcard, deep-scan variants)
  def dot_child,
    do:
      choice([
        dot_wildcard(),
        deep_scan_wildcard(),
        deep_scan()
        |> concat(choice([single_quoted_string(), double_quoted_string()])),
        ignore(dot())
        |> concat(choice([single_quoted_string(), double_quoted_string()])),
        deep_scan()
        |> concat(utf8_string([?a..?z, ?A..?Z, ?0..?9, ?$, ?_, ?-], min: 1))
        |> lookahead_not(left_paren()),
        ignore(dot())
        |> concat(utf8_string([?a..?z, ?A..?Z, ?0..?9, ?$, ?_, ?-], min: 1))
        |> lookahead_not(left_paren())
      ])
      |> tag(:dot_child)

  # Bracket-notated child or children — whitespace-tolerant: $[ 'a' , 'b' ]
  def bracket_child,
    do:
      ignore(left_bracket())
      |> whitespace()
      |> concat(quoted_key())
      |> repeat(whitespace() |> ignore(comma()) |> whitespace() |> concat(quoted_key()))
      |> whitespace()
      |> ignore(right_bracket())
      |> tag(:bracket_child)

  def field_name do
    utf8_string([?a..?z, ?A..?Z, ?0..?9, ?_, ?., ?@, ?-], min: 1)
  end

  # Quoted field names allow any content (spaces, unicode, escapes …)
  def quoted_field_name do
    choice([
      single_quoted_string(),
      double_quoted_string(),
      field_name()
    ])
  end

  def value do
    choice([
      float_value(),
      numeric_index(),
      single_quoted_string(),
      double_quoted_string(),
      boolean(),
      null()
    ])
    |> unwrap_and_tag(:value)
  end

  # list_value properly ignores brackets and commas in the AST
  def list_value do
    ignore(left_bracket())
    |> whitespace()
    |> concat(value())
    |> repeat(whitespace() |> ignore(comma()) |> whitespace() |> concat(value()), min: 1)
    |> whitespace()
    |> ignore(right_bracket())
    |> tag(:list_value)
  end

  # Quoted key (e.g., "keyName")
  def quoted_key, do: quoted_field_name()

  def operand(extra_path_steps \\ []) do
    choice([
      current_context(extra_path_steps),
      root_key(),
      list_value(),
      value()
    ])
    |> unwrap_and_tag(:operand)
  end

  def current_context(extra_path_steps \\ []),
    do:
      current()
      |> concat(optional(json_field_path(extra_path_steps)))
      |> whitespace()
      |> tag(:current_context)

  def root_key, do: root() |> repeat(choice([dot_child(), array(), bracket_child()])) |> tag(:root_key)

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

  # Float literal: optional sign, digits, dot, digits (e.g. 8.95, -0.5)
  def float_value do
    sign = optional(string("-"))
    int_part = ascii_string([?0..?9], min: 1)
    frac_part = string(".") |> concat(ascii_string([?0..?9], min: 1))

    sign
    |> concat(int_part)
    |> concat(frac_part)
    |> reduce({__MODULE__, :to_float, []})
  end

  def to_integer(x) do
    case x do
      [_sign, digits] -> -String.to_integer(digits)
      [digits] -> String.to_integer(digits)
    end
  end

  def to_float(parts) do
    parts |> Enum.join() |> String.to_float()
  end

  def join_strings(parts), do: Enum.join(parts)

  def json_field_path(extra_steps \\ []) do
    repeat(
      choice(extra_steps ++ [
        dot_child(),
        array(),
        bracket_child(),
        function()
      ])
    )
  end
end

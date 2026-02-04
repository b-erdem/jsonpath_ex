defmodule JSONPathEx.Evaluator do
  @moduledoc """
  Evaluates JSONPath Abstract Syntax Trees (ASTs) against JSON data.

  Supports JSONPath features such as filters, recursive descent, array slicing,
  logical operators, arithmetic, and built-in functions.
  """

  @comparison_operators [:<, :>, :<=, :>=, :==, :!=, :===, :in, :"not in"]
  @arithmetic_operators [:+, :-, :*, :/, :%]

  @doc """
  Evaluates a JSONPath AST against the provided JSON data.

  Returns the evaluation result or an empty list if the path doesn't match.
  """
  def evaluate(ast, json) do
    evaluate1(ast, json, json)
  end

  defp evaluate1(ast, json, original_json) do
    ast = preprocess(ast)
    Enum.reduce(ast, json, fn node, acc -> eval_ast(node, acc, original_json) end)
  end

  # ---------------------------------------------------------------------------
  # Preprocessing: merge standalone {:deep_scan, ".."} with the node that
  # follows it so the evaluator can handle them as a single operation.
  # ---------------------------------------------------------------------------
  defp preprocess([{:deep_scan, ".."}, {:bracket_child, keys} | rest]) do
    [{:deep_scan_bracket, keys} | preprocess(rest)]
  end

  defp preprocess([{:deep_scan, ".."}, {:array, array_op} | rest]) do
    [{:deep_scan_array, array_op} | preprocess(rest)]
  end

  # $...key  →  same AST shape the parser produces for $..key;
  # re-feed through preprocess so deep_scan_key can grab the next node.
  defp preprocess([{:deep_scan, ".."}, {:dot_child, [key]} | rest]) when is_binary(key) do
    preprocess([{:dot_child, [{:deep_scan, ".."}, key]} | rest])
  end

  # Trailing $.. with nothing after it
  defp preprocess([{:deep_scan, ".."} | rest]) do
    [{:deep_scan_standalone, ".."} | preprocess(rest)]
  end

  # $..key followed by another step (array, filter, function, child …)
  # → apply that step to each scan result individually.
  defp preprocess([{:dot_child, [{:deep_scan, _}, key]}, next | rest]) do
    [{:deep_scan_key, {key, next}} | preprocess(rest)]
  end

  defp preprocess([node | rest]), do: [node | preprocess(rest)]
  defp preprocess([]), do: []

  # ---------------------------------------------------------------------------
  # Core AST dispatch
  # ---------------------------------------------------------------------------
  defp eval_ast(ast, json, original_json) do
    case ast do
      {:root, _} ->
        original_json

      {:dot, _} ->
        json

      # .* on a map → its values; on a list → identity
      {:dot_child, [dot_wildcard: _]} ->
        if is_map(json), do: Map.values(json), else: json

      # ..* → all descendants
      {:dot_child, [deep_scan_wildcard: _]} ->
        deepscan(json)

      # ..key (produced by parser directly, or by preprocess for $...key)
      {:dot_child, [{:deep_scan, _}, key]} ->
        scan(json, key)

      # Single-key dot or bracket child
      {child_key, [key]} when child_key in [:dot_child, :bracket_child] ->
        get(json, key)

      # Multi-key bracket child  $['a','b']
      {:bracket_child, keys} ->
        if is_map(json) do
          Enum.reduce(keys, [], fn key, acc ->
            case Map.fetch(json, key) do
              {:ok, val} -> acc ++ [val]
              :error -> acc
            end
          end)
        else
          Enum.flat_map(keys, fn key ->
            result = get(json, key)
            if is_list(result), do: result, else: [result]
          end)
        end

      {:wildcard, _} ->
        json

      {:recursive_descent, _} ->
        json

      # Merged deep_scan nodes (from preprocess)
      {:deep_scan_key, {key, next_op}} ->
        scan(json, key)
        |> Enum.flat_map(fn node ->
          result = eval_ast(next_op, node, original_json)
          if is_list(result), do: result, else: [result]
        end)

      {:deep_scan_bracket, keys} ->
        Enum.flat_map(keys, fn key -> scan(json, key) end)

      {:deep_scan_array, array_op} ->
        collect_all_lists(json)
        |> Enum.flat_map(fn list ->
          result = eval_array(array_op, list)
          if is_list(result), do: result, else: [result]
        end)

      {:deep_scan_standalone, _} ->
        deepscan(json)

      {:array, array_op} ->
        eval_array(array_op, json)

      {:filter_expression, filters} ->
        eval_filter(json, filters, original_json)

      {:function, function} ->
        eval_function(json, function)

      {:value, [value]} ->
        value
    end
  end

  # ---------------------------------------------------------------------------
  # Key access
  # ---------------------------------------------------------------------------
  # On a list: collect values only from maps that actually have the key
  defp get(json, key) when is_list(json) do
    Enum.reduce(json, [], fn item, acc ->
      if is_map(item) && Map.has_key?(item, key) do
        [Map.get(item, key) | acc]
      else
        acc
      end
    end)
    |> Enum.reverse()
  end

  defp get(json, key) when is_map(json) do
    Map.get(json, key)
  end

  defp get(_other, _key), do: []

  # ---------------------------------------------------------------------------
  # Recursive descent helpers
  # ---------------------------------------------------------------------------
  # deepscan: all descendants, depth-first order
  defp deepscan(data) when is_map(data) do
    Enum.flat_map(data, fn {_k, v} ->
      [v] ++ deepscan(v)
    end)
  end

  defp deepscan(data) when is_list(data) do
    Enum.flat_map(data, fn v ->
      [v] ++ deepscan(v)
    end)
  end

  defp deepscan(_), do: []

  # scan: find all values for a given key at any depth, preserving order
  defp scan(map, key) when is_map(map) do
    Enum.flat_map(map, fn
      {^key, value} -> [value]
      {_k, value} when is_map(value) or is_list(value) -> scan(value, key)
      {_k, _v} -> []
    end)
  end

  defp scan(list, key) when is_list(list) do
    Enum.flat_map(list, &scan(&1, key))
  end

  defp scan(_other, _key), do: []

  # collect all lists anywhere in the tree (for deep_scan + array)
  defp collect_all_lists(data) when is_map(data) do
    Enum.flat_map(data, fn {_k, v} ->
      (if is_list(v), do: [v], else: []) ++ collect_all_lists(v)
    end)
  end

  defp collect_all_lists(data) when is_list(data) do
    [data] ++ Enum.flat_map(data, &collect_all_lists/1)
  end

  defp collect_all_lists(_), do: []

  # ---------------------------------------------------------------------------
  # Array operations
  # ---------------------------------------------------------------------------
  defp eval_array(array_op, json) when is_list(json) do
    case array_op do
      [array_wildcard: _] ->
        json

      [array_indices: indices] ->
        len = length(json)
        indices
        |> Enum.map(fn i -> if i >= 0 do i else len + i end end)
        |> Enum.filter(fn i -> i >= 0 && i < len end)
        |> Enum.map(&Enum.at(json, &1))

      [array_slice: slice_params] ->
        eval_slice(json, slice_params)
    end
  end

  # [*] on a map → its values
  defp eval_array([array_wildcard: _], json) when is_map(json) do
    Map.values(json)
  end

  defp eval_array(_, _), do: []

  # RFC 9535 slice semantics
  defp eval_slice(json, slice_params) do
    len = length(json)
    step = Keyword.get(slice_params, :step, 1)

    if step == 0 do
      []
    else
      {start, stop} =
        if step > 0 do
          s = Keyword.get(slice_params, :begin, 0)
          e = Keyword.get(slice_params, :end, len)
          {max(normalize_index(s, len), 0), min(normalize_index(e, len), len)}
        else
          s = Keyword.get(slice_params, :begin, len - 1)
          e = Keyword.get(slice_params, :end, -len - 1)
          {min(normalize_index(s, len), len - 1), max(normalize_index(e, len), -1)}
        end

      generate_indices(start, stop, step)
      |> Enum.filter(fn i -> i >= 0 && i < len end)
      |> Enum.map(&Enum.at(json, &1))
    end
  end

  defp normalize_index(i, _len) when i >= 0, do: i
  defp normalize_index(i, len), do: len + i

  defp generate_indices(i, stop, step) when step > 0 do
    if i < stop, do: [i | generate_indices(i + step, stop, step)], else: []
  end

  defp generate_indices(i, stop, step) when step < 0 do
    if i > stop, do: [i | generate_indices(i + step, stop, step)], else: []
  end

  # ---------------------------------------------------------------------------
  # Filter evaluation
  # ---------------------------------------------------------------------------
  defp eval_filter(json, filters, original_json) when is_map(json) do
    eval_filter(Map.values(json), filters, original_json)
  end

  defp eval_filter(json, filters, original_json) when is_list(json) do
    Enum.filter(json, fn x ->
      Enum.all?(filters, fn filter -> eval_term(x, filter, original_json) end)
    end)
  end

  defp eval_filter(_, _, _), do: []

  # ---------------------------------------------------------------------------
  # Term / expression evaluation with proper operator precedence:
  #   arithmetic  (+, -, *, /, %)     — highest
  #   comparison  (==, <, >, in …)
  #   logical     (&&)
  #   logical     (||)                — lowest
  # ---------------------------------------------------------------------------
  defp eval_term(json, {:term, term}, original_json) do
    sequence =
      term
      |> Enum.reduce([], fn node, acc -> eval_node(acc, node, json, original_json) end)
      |> Enum.reverse()

    result = eval_logical_or(sequence)
    # Empty nodelist (e.g. result of a nested filter) is falsy
    if result == [], do: false, else: result
  end

  # Split on || (lowest precedence)
  defp eval_logical_or(tokens) do
    tokens
    |> split_on(:||)
    |> Enum.map(&eval_logical_and/1)
    |> Enum.reduce(false, fn val, acc -> acc || val end)
  end

  # Split on &&
  defp eval_logical_and(tokens) do
    tokens
    |> split_on(:&&)
    |> Enum.map(&eval_comparison_chain/1)
    |> Enum.reduce(true, fn val, acc -> acc && val end)
  end

  # Prefix ! then arithmetic + comparison
  defp eval_comparison_chain([:! | rest]) do
    !eval_comparison_chain(rest)
  end

  defp eval_comparison_chain(tokens) do
    tokens
    |> group_by_comparisons()
    |> Enum.map(&eval_arith/1)
    |> Enum.flat_map(fn
      [op] when op in @comparison_operators -> [op]
      rpn -> evaluate_rpn(rpn)
    end)
    |> compare()
  end

  # Split a token list on every occurrence of *sep*, returning sub-lists
  defp split_on(list, sep) do
    Enum.reduce(list, [[]], fn
      ^sep, [current | rest] -> [[], current | rest]
      elem, [current | rest] -> [[elem | current] | rest]
    end)
    |> Enum.map(&Enum.reverse/1)
    |> Enum.reverse()
  end

  # ---------------------------------------------------------------------------
  # Comparison chain  [left, op, right, op, right …]
  # ---------------------------------------------------------------------------
  defp compare([]), do: nil
  defp compare([result]), do: result

  defp compare([n1, :in, list | rest]) when is_list(list) do
    compare([Enum.member?(list, n1) | rest])
  end

  defp compare([n1, :"not in", list | rest]) when is_list(list) do
    compare([!Enum.member?(list, n1) | rest])
  end

  # Ordering comparisons involving nil are always false (missing path)
  defp compare([nil, op, _ | rest]) when op in [:<, :>, :<=, :>=] do
    compare([false | rest])
  end

  defp compare([_, op, nil | rest]) when op in [:<, :>, :<=, :>=] do
    compare([false | rest])
  end

  defp compare([n1, op, n2 | rest]) do
    compare([apply(Kernel, op, [n1, n2]) | rest])
  end

  # ---------------------------------------------------------------------------
  # Node evaluation (builds the flat token sequence)
  # ---------------------------------------------------------------------------
  defp eval_node(sequence, node, json, original_json) do
    case node do
      # bare ! in the token stream (prefix negation without grouping)
      :! ->
        [:! | sequence]

      # negated grouping  !( … )
      {:grouping, [:!, group]} ->
        [!eval_term(json, group, original_json) | sequence]

      # plain grouping  ( … )
      {:grouping, [group]} ->
        [eval_term(json, group, original_json) | sequence]

      # scalar / string / boolean / null literal
      {:operand, {:value, value}} ->
        [value | sequence]

      # list literal  [2, 3]  — values are tagged {:value, v} by the parser
      {:operand, {:list_value, items}} ->
        values = Enum.map(items, fn {:value, v} -> v end)
        [values | sequence]

      # @.path  or just @
      {:operand, {:current_context, [{:current, _} | rest]}} ->
        [unwrap_nodelist(evaluate1(rest, json, original_json), rest) | sequence]

      # $.path  (root reference inside a filter)
      {:operand, {:root_key, rest}} ->
        [unwrap_nodelist(evaluate1(rest, original_json, original_json), rest) | sequence]

      {:operator, operator} ->
        [operator | sequence]
    end
  end

  # ---------------------------------------------------------------------------
  # Single-index array access in a filter operand path produces a one-element
  # nodelist; unwrap it to a scalar so comparisons work naturally.
  # Other list results (wildcards, slices, filters) stay as lists.
  # ---------------------------------------------------------------------------
  defp unwrap_nodelist([value], path) do
    case List.last(path) do
      {:array, [array_indices: [_]]} -> value
      _ -> [value]
    end
  end

  defp unwrap_nodelist(result, _path), do: result

  # ---------------------------------------------------------------------------
  # Built-in functions
  # ---------------------------------------------------------------------------
  defp eval_function(json, function) do
    case function do
      :sum -> Enum.sum(json)
      :length -> Enum.count(json)
      :min -> Enum.min(json)
      :max -> Enum.max(json)

      :avg ->
        case json do
          [] -> nil
          list -> Enum.sum(list) / length(list)
        end

      :concat -> Enum.join(json)
    end
  end

  # ---------------------------------------------------------------------------
  # Arithmetic helpers (shunting-yard → RPN → evaluate)
  # ---------------------------------------------------------------------------
  # group_by_comparisons splits the flat token list into segments separated
  # by comparison operators, which are kept as single-element lists.
  defp group_by_comparisons(list) do
    Enum.reduce(list, {[], []}, fn
      elem, {acc, current} when elem in @comparison_operators ->
        {acc ++ [current] ++ [[elem]], []}

      elem, {acc, current} ->
        {acc, current ++ [elem]}
    end)
    |> then(fn {acc, current} -> acc ++ [current] end)
  end

  # Shunting-yard: infix arithmetic → RPN.
  # Condition fixed: pop while stack-top precedence >= current op precedence
  # (left-associative).  Non-arithmetic tokens (strings, booleans, nil, lists)
  # pass straight through to the output.
  defp eval_arith(list) do
    precedence = %{:* => 2, :/ => 2, :% => 2, :+ => 1, :- => 1}

    {output, stack} =
      list
      |> Enum.reduce({[], []}, fn
        op, {output, stack} when op in @arithmetic_operators ->
          {to_pop, new_stack} =
            Enum.split_while(stack, fn s ->
              Map.get(precedence, s, 0) >= Map.get(precedence, op)
            end)

          {Enum.reverse(to_pop) ++ output, [op | new_stack]}

        x, {output, stack} ->
          {[x | output], stack}
      end)

    Enum.reverse(output) ++ stack
  end

  # RPN evaluator: only arithmetic operators trigger apply; everything else
  # (numbers, strings, booleans, nil, lists) is a value.
  defp evaluate_rpn(rpn) do
    Enum.reduce(rpn, [], fn
      op, [n2, n1 | rest] when op in @arithmetic_operators ->
        if is_number(n1) && is_number(n2) do
          result = if op == :% do rem(n1, n2) else apply(Kernel, op, [n1, n2]) end
          [result | rest]
        else
          [nil | rest]
        end

      val, stack ->
        [val | stack]
    end)
  end
end

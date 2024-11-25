defmodule JsonpathEx.Evaluator do
  @comparison_operators [:<, :>, :<=, :>=, :==, :!=]

  def evaluate(ast, json) do
    evaluate1(ast, json, json)
  end

  def evaluate1(ast, json, original_json) do
    Enum.reduce(ast, json, fn node, acc -> eval_ast(node, acc, original_json) end)
  end

  def eval_ast(ast, json, original_json) do
    case ast do
      {:root, _} ->
        original_json

      {:dot, _} ->
        json

      {:dot_child, [dot_wildcard: _]} ->
        json

      {:dot_child, [deep_scan_wildcard: _]} ->
        deepscan(json)

      {:dot_child, [{:deep_scan, _}, key]} ->
        scan(json, key)

      {child_key, [key]} when child_key in [:dot_child, :bracket_child] ->
        get(json, key)

      {:wildcard, _} ->
        json

      {:recursive_descent, _} ->
        json

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

  def get(json, key) when is_list(json) do
    Enum.map(json, &Map.get(&1, key))
  end

  def get(json, key) when is_map(json) do
    Map.get(json, key)
  end

  def get(_other, _key), do: []

  def deepscan(data) do
    Enum.reduce(data, [], fn
      {_k, v}, acc when is_map(v) -> [v | acc] ++ deepscan(v)
      {_k, v}, acc when is_list(v) -> [v | acc] ++ deepscan(v)
      {_k, v}, acc -> [v | acc]
      v, acc -> [v | acc]
    end)
  end

  # TODO: extract to separate module
  def scan(map, key) when is_map(map) do
    map
    |> Enum.reduce([], fn
      # Check if the current key matches the search key
      {^key, value}, acc -> [value | acc]
      # Recursive call to scan nested maps or lists
      {_k, value}, acc when is_map(value) or is_list(value) -> [scan(value, key) | acc]
      # Skip if the current key does not match and value is not a map or list
      {_k, _v}, acc -> acc
    end)
    |> List.flatten()
  end

  def scan(list, key) when is_list(list) do
    list
    |> Enum.map(&scan(&1, key))
    |> List.flatten()
  end

  def scan(_other, _key), do: []

  def eval_array(array_op, json) when is_list(json) do
    case array_op do
      [array_wildcard: _] ->
        json

      [array_indices: indices] ->
        indices |> Enum.map(&Enum.at(json, &1))

      [array_slice: slice_params] ->
        start = Keyword.get(slice_params, :begin, 0)
        stop = Keyword.get(slice_params, :end, length(json))
        step = Keyword.get(slice_params, :step, 1)

        json
        |> Enum.slice(start, stop - start)
        |> Enum.take_every(step)
    end
  end

  def eval_array(_, _), do: []

  def eval_filter(json, filters, original_json) do
    json
    |> Enum.filter(fn x ->
      filters
      |> Enum.reduce(true, fn filter, _acc ->
        eval_term(x, filter, original_json)
      end)
    end)
  end

  def eval_term(json, {:term, term}, original_json) do
    sequence =
      Enum.reduce(term, [], fn node, acc ->
        eval_node(acc, node, json, original_json)
      end)

    sequence
    |> Enum.reject(&is_nil/1)
    |> Enum.reverse()
    |> group_by_comparisons()
    |> Enum.map(&eval_arith/1)
    |> Enum.flat_map(fn
      [op] when op in @comparison_operators -> [op]
      rpn -> evaluate_rpn(rpn)
    end)
    |> compare()
  end

  def compare([]), do: nil
  def compare([result]), do: result

  def compare([n1, op, n2 | rest]) do
    compare([apply(Kernel, op, [n1, n2]) | rest])
  end

  def eval_node(sequence, node, json, original_json) do
    case node do
      # {:not, _} -> {json, ["!" | sequence]}
      {:grouping, [group]} ->
        [eval_term(json, group, original_json) | sequence]

      {:operand, {:value, value}} ->
        [value | sequence]

      {:operand, {:current_context, [{:current, _} | rest]}} ->
        [evaluate1(rest, json, original_json) | sequence]

      {:operand, {:root_key, rest}} ->
        [evaluate1(rest, original_json, original_json) | sequence]

      {:operator, operator} ->
        [operator | sequence]
    end
  end

  def eval_function(json, function) do
    case function do
      :sum -> Enum.sum(json)
      :length -> Enum.count(json)
      :min -> Enum.min(json)
      :max -> Enum.max(json)
    end
  end

  def group_by_comparisons(list) do
    Enum.reduce(list, {[], []}, fn
      # If the element is a comparison operator, push the current group to the accumulator and start a new group with just the operator
      elem, {acc, current} when elem in @comparison_operators ->
        {acc ++ [current] ++ [[elem]], []}

      elem, {acc, current} ->
        {acc, current ++ [elem]}
    end)
    |> then(fn {acc, current} -> acc ++ [current] end)
  end

  def eval_arith(list) do
    precedence = %{:* => 2, :/ => 2, :% => 2, :+ => 1, :- => 1}

    {output, stack} =
      list
      |> Enum.reduce({[], []}, fn
        x, {output, stack} when is_number(x) ->
          {[x | output], stack}

        op, {output, stack} ->
          {new_stack, new_output} =
            Enum.split_while(stack, fn s -> Map.get(precedence, op) >= Map.get(precedence, s) end)

          {Enum.reverse(new_output) ++ output, Enum.reverse([op | new_stack])}
      end)

    Enum.reverse(output) ++ Enum.reverse(stack)
  end

  def evaluate_rpn(rpn) do
    Enum.reduce(rpn, [], fn
      num, stack when is_number(num) or is_binary(num) -> [num | stack]
      op, [n2, n1 | rest] -> [apply(Kernel, op, [n1, n2]) | rest]
    end)
  end
end

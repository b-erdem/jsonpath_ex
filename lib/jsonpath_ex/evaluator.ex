defmodule JsonpathEx.Evaluator do
  def evaluate(ast, json) do
    evaluate1(ast, json, json)
  end

  def evaluate1(ast, json, original_json) do
    ast
    |> Enum.reduce(json, fn node, acc -> eval_ast(node, acc, original_json) end)
  end

  def eval_ast(ast, json, original_json) do
    case ast do
      {:root, _root} ->
        json

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

  def get(json, key) do
    Map.get(json, key)
  end

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

  def eval_array(array_op, json) do
    case array_op do
      [array_wildcard: _] -> json
      [array_indices: [indice]] -> Enum.at(json, indice)
      [array_indices: [_h | _t] = indices] -> indices |> Enum.map(&Enum.at(json, &1))
      [array_slice: []] -> json
      [array_slice: [begin: begin, end: end_]] -> Enum.slice(json, begin, end_)
      [array_slice: [begin: begin]] -> Enum.slice(json, begin, length(json))
      [array_slice: [end: end_]] -> Enum.slice(json, 0, end_)
    end
  end

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
    |> Enum.reverse()
    |> calculate()
  end

  def calculate([result]), do: result

  def calculate([n1, op, n2 | rest]) do
    calculate([apply(Kernel, op, [n1, n2]) | rest])
  end

  def eval_node(sequence, node, json, original_json) do
    case node do
      # {:not, _} -> {json, ["!" | sequence]}
      {:grouping, [group]} ->
        [eval_term(json, group, original_json) | sequence]

      {:operand, {:value, value}} ->
        [value | sequence]

      {:operand, {:current_context, [{:current, _v} | rest]}} ->
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
end

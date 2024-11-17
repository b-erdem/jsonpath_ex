defmodule JsonpathEx.Evaluator do
  def evaluate(ast, json) do
    ast
    |> Enum.reduce(json, fn node, acc -> eval_ast(node, acc) end)
  end

  def eval_ast(ast, json) do
    case ast do
      {:root, _root} ->
        json

      {:dot, _} ->
        json

      {:dot_child, [dot_wildcard: _]} ->
        json

      # {:dot_child, [deep_scan_wildcard: _]} -> json
      {:dot_child, [{:deep_scan, _}, key]} ->
        scan(json, key)

      {:dot_child, [_, key]} ->
        if is_list(json), do: Enum.map(json, &Map.get(&1, key)), else: Map.get(json, key)

      {:bracket_child, [field_name: [field_name]]} ->
        if is_list(json),
          do: Enum.map(json, &Map.get(&1, field_name)),
          else: Map.get(json, field_name)

      {:field, field} ->
        Map.get(json, field)

      {:wildcard, _} ->
        json

      {:recursive_descent, _} ->
        eval_recursive_descent(json)

      {:array, array_op} ->
        eval_array(array_op, json)

      {:filter_expression, filters} ->
        eval_filter(json, filters)

      {:function, function} ->
        eval_function(json, function)

      {:value, [value]} ->
        value
    end
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

  def eval_recursive_descent(json) do
    json
  end

  def eval_array(array_op, json) do
    case array_op do
      [array_wildcard: _] -> json
      [array_indices: indices] -> indices |> Enum.map(&Enum.at(json, &1))
      [array_slice: []] -> json
      [array_slice: [end: [end_]]] -> Enum.slice(json, 0, end_)
      [array_slice: [begin: [begin]]] -> Enum.slice(json, begin, length(json))
      [array_slice: [begin: [begin], end: [end_]]] -> Enum.slice(json, begin, end_)
    end
  end

  def eval_filter(json, filters) do
    filters
    |> Enum.reduce(json, fn filter, acc -> acc end)
  end

  def eval_logical_expression(json, lhs, operator, rhs) do
    {:logical_operator, [{_, [operator]}]} = operator

    Enum.filter(json, fn x ->
      lhs_value = eval_lhs(x, lhs)
      rhs_value = eval_rhs(x, rhs)

      case operator do
        "==" -> lhs_value == rhs_value
        "!=" -> lhs_value != rhs_value
        "<" -> lhs_value < rhs_value
        "<=" -> lhs_value <= rhs_value
        ">" -> lhs_value > rhs_value
        ">=" -> lhs_value >= rhs_value
      end
    end)
  end

  def eval_lhs(json, current_context) do
    case current_context do
      {:operand, [current_context: [_, lhs]]} -> eval_ast(json, lhs)
    end
  end

  def eval_rhs(json, rhs) do
    case rhs do
      {:current_context, [_, rhs]} -> eval_ast(json, rhs)
      other -> eval_ast(json, other)
    end
  end

  def eval_arithmetic_expression(json, lhs, operator, rhs) do
    case operator do
      "+" -> eval_ast(json, lhs) + eval_ast(json, rhs)
      "-" -> eval_ast(json, lhs) - eval_ast(json, rhs)
      "*" -> eval_ast(json, lhs) * eval_ast(json, rhs)
      "/" -> eval_ast(json, lhs) / eval_ast(json, rhs)
    end
  end

  def eval_function(json, function) do
    case function do
      [sum: _] -> Enum.sum(json)
      [length: _] -> Enum.count(json)
      [min: _] -> Enum.min(json)
      [max: _] -> Enum.max(json)
    end
  end
end

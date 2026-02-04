defmodule JSONPathExTest do
  use ExUnit.Case
  doctest JSONPathEx

  # ---------------------------------------------------------------------------
  # Shared fixture: the classic bookstore document
  # ---------------------------------------------------------------------------
  @store %{
    "store" => %{
      "book" => [
        %{
          "category" => "reference",
          "author" => "Nigel Rees",
          "title" => "Sayings of the Century",
          "price" => 8.95
        },
        %{
          "category" => "fiction",
          "author" => "Evelyn Waugh",
          "title" => "Sword of Honour",
          "price" => 12.99
        },
        %{
          "category" => "fiction",
          "author" => "Herman Melville",
          "title" => "Moby Dick",
          "isbn" => "0-553-21311-3",
          "price" => 8.99
        },
        %{
          "category" => "fiction",
          "author" => "J. R. R. Tolkien",
          "title" => "The Lord of the Rings",
          "isbn" => "0-395-19395-8",
          "price" => 22.99
        }
      ],
      "bicycle" => %{"color" => "red", "price" => 19.95}
    },
    "expensive" => 10
  }

  # ---------------------------------------------------------------------------
  # 1.  Root selector
  # ---------------------------------------------------------------------------
  test "root selector returns the whole document" do
    assert {:ok, %{"a" => 1}} == JSONPathEx.evaluate("$", %{"a" => 1})
    assert {:ok, [1, 2, 3]} == JSONPathEx.evaluate("$", [1, 2, 3])
    assert {:ok, 42} == JSONPathEx.evaluate("$", 42)
    assert {:ok, true} == JSONPathEx.evaluate("$", true)
    assert {:ok, false} == JSONPathEx.evaluate("$", false)
    assert {:ok, nil} == JSONPathEx.evaluate("$", nil)
    assert {:ok, "hello"} == JSONPathEx.evaluate("$", "hello")
  end

  # ---------------------------------------------------------------------------
  # 2.  Dot-child navigation
  # ---------------------------------------------------------------------------
  test "dot child — single and chained" do
    assert {:ok, 1} == JSONPathEx.evaluate("$.a", %{"a" => 1, "b" => 2})
    assert {:ok, 42} == JSONPathEx.evaluate("$.a.b", %{"a" => %{"b" => 42}})
    assert {:ok, "deep"} ==
             JSONPathEx.evaluate("$.a.b.c", %{"a" => %{"b" => %{"c" => "deep"}}})
  end

  test "dot child — missing key returns nil" do
    assert {:ok, nil} == JSONPathEx.evaluate("$.missing", %{"a" => 1})
    assert {:ok, nil} == JSONPathEx.evaluate("$.a.missing", %{"a" => %{"b" => 2}})
  end

  test "dot child — keyword-like key names" do
    # words that look like keywords are just key names in dot notation
    assert {:ok, "inside"} == JSONPathEx.evaluate("$.in", %{"in" => "inside"})
    assert {:ok, "not-null"} == JSONPathEx.evaluate("$.null", %{"null" => "not-null"})
    assert {:ok, "yes"} == JSONPathEx.evaluate("$.true", %{"true" => "yes"})
    assert {:ok, 42} == JSONPathEx.evaluate("$.length", %{"length" => 42})
  end

  test "dot child — hyphenated and numeric keys" do
    assert {:ok, "hyphenated"} == JSONPathEx.evaluate("$.my-key", %{"my-key" => "hyphenated"})
    assert {:ok, "two"} == JSONPathEx.evaluate("$.2", %{"2" => "two"})
    assert {:ok, "neg"} == JSONPathEx.evaluate("$.-1", %{"-1" => "neg"})
  end

  # ---------------------------------------------------------------------------
  # 3.  Bracket-child navigation
  # ---------------------------------------------------------------------------
  test "bracket child — single key" do
    assert {:ok, 1} == JSONPathEx.evaluate("$['a']", %{"a" => 1})
    assert {:ok, 99} == JSONPathEx.evaluate("$['a']['b']", %{"a" => %{"b" => 99}})
  end

  test "bracket child — special-character keys" do
    assert {:ok, "spaced"} ==
             JSONPathEx.evaluate("$['key with spaces']", %{"key with spaces" => "spaced"})
    assert {:ok, "dotted"} == JSONPathEx.evaluate("$['a.b']", %{"a.b" => "dotted"})
    assert {:ok, "colon"} == JSONPathEx.evaluate("$[':']", %{":" => "colon"})
    assert {:ok, "comma"} == JSONPathEx.evaluate("$[',']", %{"," => "comma"})
    assert {:ok, "star"} == JSONPathEx.evaluate("$['*']", %{"*" => "star"})
    assert {:ok, "dollar"} == JSONPathEx.evaluate("$['$']", %{"$" => "dollar"})
    assert {:ok, "empty"} == JSONPathEx.evaluate("$['']", %{"" => "empty"})
  end

  test "bracket child — unicode key" do
    assert {:ok, "umlaut"} == JSONPathEx.evaluate("$['ü']", %{"ü" => "umlaut"})
  end

  # ---------------------------------------------------------------------------
  # 4.  Multi-key bracket
  # ---------------------------------------------------------------------------
  test "multi-key bracket on map" do
    data = %{"a" => 1, "b" => 2, "c" => 3}

    # order follows the bracket, not the map
    assert {:ok, [2, 1]} == JSONPathEx.evaluate("$['b','a']", data)
    assert {:ok, [1, 2, 3]} == JSONPathEx.evaluate("$['a','b','c']", data)

    # missing keys are silently skipped
    assert {:ok, [1]} == JSONPathEx.evaluate("$['a','missing']", data)

    # duplicate keys yield duplicate values
    assert {:ok, [1, 1]} == JSONPathEx.evaluate("$['a','a']", data)
  end

  test "multi-key bracket on list of maps" do
    data = [
      %{"c" => "cc1", "d" => "dd1", "e" => "ee1"},
      %{"c" => "cc2", "d" => "dd2", "e" => "ee2"}
    ]

    # single element first
    assert {:ok, ["cc1", "dd1"]} == JSONPathEx.evaluate("$[0]['c','d']", data)
    # all elements via wildcard/slice
    assert {:ok, ["cc1", "cc2", "dd1", "dd2"]} == JSONPathEx.evaluate("$.*['c','d']", data)
    assert {:ok, ["cc1", "cc2", "dd1", "dd2"]} == JSONPathEx.evaluate("$[:][ 'c' , 'd' ]", data)
  end

  # ---------------------------------------------------------------------------
  # 5.  Wildcards
  # ---------------------------------------------------------------------------
  test "wildcard on map returns all values" do
    assert {:ok, result} = JSONPathEx.evaluate("$.*", %{"a" => 1, "b" => 2})
    assert Enum.sort(result) == [1, 2]

    assert {:ok, result} = JSONPathEx.evaluate("$[*]", %{"x" => "X", "y" => "Y"})
    assert Enum.sort(result) == ["X", "Y"]
  end

  test "wildcard on list returns the list" do
    assert {:ok, [1, 2, 3]} == JSONPathEx.evaluate("$[*]", [1, 2, 3])
    assert {:ok, ["a", "b"]} == JSONPathEx.evaluate("$.*", ["a", "b"])
  end

  test "wildcard then key — collects from each element" do
    assert {:ok, ["first", "second"]} ==
             JSONPathEx.evaluate("$[*].name", [%{"name" => "first"}, %{"name" => "second"}])
  end

  # ---------------------------------------------------------------------------
  # 6.  Array indices
  # ---------------------------------------------------------------------------
  test "single array index" do
    list = ["a", "b", "c", "d", "e"]
    assert {:ok, ["a"]} == JSONPathEx.evaluate("$[0]", list)
    assert {:ok, ["c"]} == JSONPathEx.evaluate("$[2]", list)
    assert {:ok, ["e"]} == JSONPathEx.evaluate("$[-1]", list)
    assert {:ok, ["d"]} == JSONPathEx.evaluate("$[-2]", list)
  end

  test "out-of-bounds index returns empty" do
    assert {:ok, []} == JSONPathEx.evaluate("$[100]", ["a", "b", "c"])
    assert {:ok, []} == JSONPathEx.evaluate("$[-100]", ["a", "b", "c"])
  end

  test "multiple indices — order and duplicates" do
    list = ["first", "second", "third", "fourth", "fifth"]
    assert {:ok, ["third", "second"]} == JSONPathEx.evaluate("$[2,1]", list)
    assert {:ok, ["first", "second"]} == JSONPathEx.evaluate("$[0,1]", list)
    assert {:ok, ["fifth", "second"]} == JSONPathEx.evaluate("$[4,1]", list)
    assert {:ok, ["a", "a"]} == JSONPathEx.evaluate("$[0,0]", ["a", "b"])
  end

  test "whitespace-tolerant indices" do
    assert {:ok, ["first", "second"]} ==
             JSONPathEx.evaluate("$[ 0 , 1 ]", ["first", "second", "third"])
  end

  test "chained index then key" do
    assert {:ok, ["first"]} ==
             JSONPathEx.evaluate("$[0].name", [%{"name" => "first"}, %{"name" => "second"}])
  end

  # ---------------------------------------------------------------------------
  # 7.  Array slicing (RFC 9535)
  # ---------------------------------------------------------------------------
  test "basic slices" do
    list = ["a", "b", "c", "d", "e"]
    assert {:ok, ["b", "c"]} == JSONPathEx.evaluate("$[1:3]", list)
    assert {:ok, ["a", "b"]} == JSONPathEx.evaluate("$[:2]", list)
    assert {:ok, ["c", "d", "e"]} == JSONPathEx.evaluate("$[2:]", list)
    assert {:ok, list} == JSONPathEx.evaluate("$[:]", list)
    assert {:ok, list} == JSONPathEx.evaluate("$[::]", list)
  end

  test "slice with step" do
    list = ["a", "b", "c", "d", "e", "f"]
    assert {:ok, ["a", "c", "e"]} == JSONPathEx.evaluate("$[::2]", list)
    assert {:ok, ["b", "d", "f"]} == JSONPathEx.evaluate("$[1::2]", list)
  end

  test "negative-index slice" do
    list = ["a", "b", "c", "d", "e"]
    assert {:ok, ["d", "e"]} == JSONPathEx.evaluate("$[-2:]", list)
    assert {:ok, ["a", "b", "c"]} == JSONPathEx.evaluate("$[:-2]", list)
  end

  test "negative-step slice (reverse)" do
    list = ["a", "b", "c", "d", "e"]
    assert {:ok, ["e", "d", "c", "b", "a"]} == JSONPathEx.evaluate("$[::-1]", list)
    assert {:ok, ["d", "c", "b"]} == JSONPathEx.evaluate("$[3:0:-1]", list)
  end

  test "step zero returns empty" do
    assert {:ok, []} == JSONPathEx.evaluate("$[::0]", ["a", "b", "c"])
  end

  test "out-of-bounds slice is clamped" do
    assert {:ok, ["a", "b", "c"]} == JSONPathEx.evaluate("$[0:100]", ["a", "b", "c"])
    assert {:ok, ["a", "b", "c"]} == JSONPathEx.evaluate("$[-100:100]", ["a", "b", "c"])
  end

  test "empty-range slice returns empty" do
    # start >= stop with positive step
    assert {:ok, []} == JSONPathEx.evaluate("$[2:1]", ["a", "b", "c", "d"])
    assert {:ok, []} == JSONPathEx.evaluate("$[3:3]", ["a", "b", "c", "d"])
  end

  # ---------------------------------------------------------------------------
  # 8.  Recursive descent — key scan
  # ---------------------------------------------------------------------------
  test "recursive descent finds key at all depths" do
    data = %{"a" => 1, "b" => %{"a" => 2, "c" => %{"a" => 3}}}
    assert {:ok, [1, 2, 3]} == JSONPathEx.evaluate("$..a", data)
  end

  test "recursive descent on list root" do
    data = [%{"name" => "A"}, %{"child" => %{"name" => "B"}}]
    assert {:ok, ["A", "B"]} == JSONPathEx.evaluate("$..name", data)
  end

  test "recursive descent on empty structures" do
    assert {:ok, []} == JSONPathEx.evaluate("$..key", %{})
    assert {:ok, []} == JSONPathEx.evaluate("$..key", [])
  end

  # ---------------------------------------------------------------------------
  # 9.  Recursive descent + subsequent selector (deep_scan_key)
  # ---------------------------------------------------------------------------
  test "deep scan key + array index" do
    # use a list root so order is deterministic
    data = [%{"items" => ["fx"]}, %{"items" => ["fy"]}]
    assert {:ok, ["fx", "fy"]} == JSONPathEx.evaluate("$..items[0]", data)
  end

  test "deep scan key + array wildcard" do
    data = [%{"items" => [1, 2]}, %{"items" => [3]}]
    assert {:ok, [1, 2, 3]} == JSONPathEx.evaluate("$..items[*]", data)
  end

  test "deep scan key + slice" do
    data = [%{"items" => ["a", "b", "c"]}, %{"items" => ["d", "e"]}]
    assert {:ok, ["b", "c", "e"]} == JSONPathEx.evaluate("$..items[1:]", data)
  end

  test "deep scan key + filter" do
    data = [
      %{"nums" => [%{"v" => 1}, %{"v" => 5}]},
      %{"nums" => [%{"v" => 10}, %{"v" => 2}]}
    ]
    assert {:ok, [%{"v" => 5}, %{"v" => 10}]} ==
             JSONPathEx.evaluate("$..nums[?(@.v > 3)]", data)
  end

  test "deep scan key + function" do
    data = [%{"items" => [1, 2, 3]}, %{"items" => [4, 5]}]
    assert {:ok, [3, 2]} == JSONPathEx.evaluate("$..items.length()", data)
  end

  test "deep scan key + chained child access" do
    # $..book.author  →  scan for "book", then get "author" from each result
    # (book is an array → get collects "author" from each map in it)
    assert {:ok, ["Nigel Rees", "Evelyn Waugh", "Herman Melville", "J. R. R. Tolkien"]} ==
             JSONPathEx.evaluate("$..book.author", @store)
  end

  # ---------------------------------------------------------------------------
  # 10.  Deep scan bracket (multiple keys)
  # ---------------------------------------------------------------------------
  test "deep scan bracket collects all occurrences of each key" do
    data = [
      %{"c" => "cc1", "d" => "dd1"},
      %{"c" => "cc2", "child" => %{"d" => "dd2"}},
      %{"c" => "cc3"},
      %{"d" => "dd4"},
      %{"child" => %{"c" => "cc5"}}
    ]
    assert {:ok, result} = JSONPathEx.evaluate("$..['c','d']", data)
    assert Enum.sort(result) == Enum.sort(["cc1", "cc2", "cc3", "cc5", "dd1", "dd2", "dd4"])
  end

  # ---------------------------------------------------------------------------
  # 11.  Standalone deep scan  ($..  and $.key..)
  # ---------------------------------------------------------------------------
  test "trailing deep scan returns all descendants" do
    data = %{"complex" => "string", "primitives" => [0, 1]}
    assert {:ok, result} = JSONPathEx.evaluate("$.key..", %{"key" => data})
    # descendants: "string", [0,1], 0, 1
    assert "string" in result
    assert [0, 1] in result
    assert 0 in result
    assert 1 in result
    assert length(result) == 4
  end

  test "$.* (all descendants) on nested structure" do
    data = %{"a" => %{"b" => 1}, "c" => 2}
    assert {:ok, result} = JSONPathEx.evaluate("$..*", data)
    assert %{"b" => 1} in result
    assert 1 in result
    assert 2 in result
  end

  test "$.* on empty structures returns empty" do
    assert {:ok, []} == JSONPathEx.evaluate("$..*", %{})
    assert {:ok, []} == JSONPathEx.evaluate("$..*", [])
  end

  # ---------------------------------------------------------------------------
  # 12.  Filters — existence
  # ---------------------------------------------------------------------------
  test "filter existence — truthy values pass" do
    data = [
      %{"key" => 1},
      %{"other" => 2},
      %{"key" => nil},
      %{"key" => false},
      %{"key" => 0},
      %{"key" => ""}
    ]
    # nil and false are falsy; 0 and "" are truthy in Elixir
    assert {:ok, [%{"key" => 1}, %{"key" => 0}, %{"key" => ""}]} ==
             JSONPathEx.evaluate("$[?(@.key)]", data)
  end

  test "filter negated existence" do
    data = [%{"title" => "A", "isbn" => "x"}, %{"title" => "B"}, %{"title" => "C", "isbn" => "y"}]
    assert {:ok, [%{"title" => "B"}]} == JSONPathEx.evaluate("$[?!@.isbn]", data)
  end

  test "filter bare current — truthy items only" do
    # nil, false, and [] (empty nodelist) filtered out; 0 and %{} are truthy
    assert {:ok, [1, "hello", 0, %{}]} ==
             JSONPathEx.evaluate("$[?(@)]", [1, nil, "hello", false, 0, [], %{}])
  end

  test "filter literal true/false/null" do
    items = [%{"a" => 1}, %{"a" => 2}]
    assert {:ok, items} == JSONPathEx.evaluate("$[?(true)]", items)
    assert {:ok, []} == JSONPathEx.evaluate("$[?(false)]", items)
    assert {:ok, []} == JSONPathEx.evaluate("$[?(null)]", items)
  end

  test "filter always-true literal comparison" do
    items = [%{"a" => 1}, %{"a" => 2}]
    assert {:ok, items} == JSONPathEx.evaluate("$[?(1 == 1)]", items)
  end

  # ---------------------------------------------------------------------------
  # 13.  Filters — comparison operators
  # ---------------------------------------------------------------------------
  test "filter numeric comparisons" do
    data = [%{"v" => 1}, %{"v" => 5}, %{"v" => 10}, %{"v" => 15}]

    assert {:ok, [%{"v" => 10}, %{"v" => 15}]} ==
             JSONPathEx.evaluate("$[?(@.v > 8)]", data)
    assert {:ok, [%{"v" => 10}, %{"v" => 15}]} ==
             JSONPathEx.evaluate("$[?(@.v >= 10)]", data)
    assert {:ok, [%{"v" => 1}, %{"v" => 5}]} ==
             JSONPathEx.evaluate("$[?(@.v < 8)]", data)
    assert {:ok, [%{"v" => 1}, %{"v" => 5}, %{"v" => 10}]} ==
             JSONPathEx.evaluate("$[?(@.v <= 10)]", data)
  end

  test "filter equality and inequality" do
    data = [%{"v" => 1}, %{"v" => 2}, %{"v" => 1}]
    assert {:ok, [%{"v" => 1}, %{"v" => 1}]} == JSONPathEx.evaluate("$[?(@.v == 1)]", data)
    assert {:ok, [%{"v" => 2}]} == JSONPathEx.evaluate("$[?(@.v != 1)]", data)
  end

  test "filter string equality" do
    data = [%{"name" => "Alice"}, %{"name" => "Bob"}, %{"name" => "Alice"}]
    assert {:ok, [%{"name" => "Alice"}, %{"name" => "Alice"}]} ==
             JSONPathEx.evaluate("$[?(@.name == 'Alice')]", data)
    assert {:ok, [%{"name" => "Bob"}]} ==
             JSONPathEx.evaluate("$[?(@.name != 'Alice')]", data)
  end

  test "filter float comparison" do
    data = [%{"v" => 1.0}, %{"v" => 2.5}, %{"v" => 0.5}]
    assert {:ok, [%{"v" => 2.5}]} == JSONPathEx.evaluate("$[?(@.v > 1.5)]", data)
  end

  test "filter strict equality ===" do
    # === is Elixir's === which is identical to ==; in practice distinguishes
    # integer 42 from float 42.0 and string "42"
    data = [%{"v" => 42}, %{"v" => 42.0}, %{"v" => "42"}]
    assert {:ok, [%{"v" => 42}]} == JSONPathEx.evaluate("$[?(@.v === 42)]", data)
  end

  test "filter null comparison" do
    data = [%{"v" => nil}, %{"v" => 1}, %{"v" => "x"}]
    assert {:ok, [%{"v" => nil}]} == JSONPathEx.evaluate("$[?(@.v == null)]", data)
    assert {:ok, [%{"v" => 1}, %{"v" => "x"}]} ==
             JSONPathEx.evaluate("$[?(@.v != null)]", data)
  end

  test "filter boolean comparison" do
    data = [%{"active" => true}, %{"active" => false}, %{"active" => nil}]
    assert {:ok, [%{"active" => true}]} ==
             JSONPathEx.evaluate("$[?(@.active == true)]", data)
    assert {:ok, [%{"active" => false}]} ==
             JSONPathEx.evaluate("$[?(@.active == false)]", data)
  end

  test "filter ordering comparison with missing key yields false" do
    # missing key → nil; nil < 5 is false (not Elixir term order)
    data = [%{"other" => 1}, %{"missing" => 3}, %{"missing" => 7}]
    assert {:ok, [%{"missing" => 3}]} ==
             JSONPathEx.evaluate("$[?(@.missing < 5)]", data)
  end

  # ---------------------------------------------------------------------------
  # 14.  Filters — logical operators
  # ---------------------------------------------------------------------------
  test "filter AND" do
    data = [%{"price" => 8.95}, %{"price" => 12.99}, %{"price" => 19.95}, %{"price" => 22.99}]
    assert {:ok, [%{"price" => 12.99}, %{"price" => 19.95}]} ==
             JSONPathEx.evaluate("$[?(@.price > 10 && @.price < 20)]", data)
  end

  test "filter OR" do
    data = [%{"price" => 8.95}, %{"price" => 12.99}, %{"price" => 19.95}, %{"price" => 22.99}]
    assert {:ok, [%{"price" => 8.95}, %{"price" => 22.99}]} ==
             JSONPathEx.evaluate("$[?(@.price < 9 || @.price > 20)]", data)
  end

  test "filter NOT with grouping" do
    data = [%{"a" => 1}, %{"a" => 2}, %{"a" => 3}]
    assert {:ok, [%{"a" => 2}, %{"a" => 3}]} ==
             JSONPathEx.evaluate("$[?!(@.a == 1)]", data)
  end

  test "AND binds tighter than OR" do
    # a==1 || (b==2 && c==3)
    data = [
      %{"a" => 1, "b" => 0, "c" => 0},  # passes: a==1
      %{"a" => 0, "b" => 2, "c" => 3},  # passes: b==2 && c==3
      %{"a" => 0, "b" => 2, "c" => 0},  # fails: b==2 but c!=3, and a!=1
      %{"a" => 0, "b" => 0, "c" => 3}   # fails: c==3 but b!=2, and a!=1
    ]
    assert {:ok, [
              %{"a" => 1, "b" => 0, "c" => 0},
              %{"a" => 0, "b" => 2, "c" => 3}
            ]} ==
             JSONPathEx.evaluate("$[?(@.a == 1 || @.b == 2 && @.c == 3)]", data)
  end

  test "explicit grouping overrides precedence" do
    # (a==1 || a==2) && b==true
    data = [
      %{"a" => 1, "b" => true},   # passes
      %{"a" => 2, "b" => false},  # fails: b!=true
      %{"a" => 3, "b" => true},   # fails: a not 1 or 2
      %{"a" => 2, "b" => true}    # passes
    ]
    assert {:ok, [%{"a" => 1, "b" => true}, %{"a" => 2, "b" => true}]} ==
             JSONPathEx.evaluate("$[?((@.a == 1 || @.a == 2) && @.b == true)]", data)
  end

  # ---------------------------------------------------------------------------
  # 15.  Filters — in / not in
  # ---------------------------------------------------------------------------
  test "filter in operator" do
    data = [%{"cat" => 1}, %{"cat" => 5}, %{"cat" => 3}]
    assert {:ok, [%{"cat" => 1}, %{"cat" => 3}]} ==
             JSONPathEx.evaluate("$[?(@.cat in [1,2,3])]", data)
  end

  test "filter nin (not in) operator" do
    data = [%{"v" => 1}, %{"v" => 4}, %{"v" => 2}, %{"v" => 5}]
    assert {:ok, [%{"v" => 4}, %{"v" => 5}]} ==
             JSONPathEx.evaluate("$[?(@.v nin [1,2,3])]", data)
  end

  test "filter in with strings" do
    data = [%{"v" => "a"}, %{"v" => "c"}, %{"v" => "b"}]
    assert {:ok, [%{"v" => "a"}, %{"v" => "b"}]} ==
             JSONPathEx.evaluate("$[?(@.v in ['a','b'])]", data)
  end

  # ---------------------------------------------------------------------------
  # 16.  Filters — arithmetic
  # ---------------------------------------------------------------------------
  test "filter addition" do
    data = [%{"v" => 3}, %{"v" => 7}, %{"v" => 5}]
    assert {:ok, [%{"v" => 7}]} == JSONPathEx.evaluate("$[?(@.v + 3 == 10)]", data)
  end

  test "filter subtraction" do
    data = [%{"key" => 60}, %{"key" => -50}, %{"key" => 10}]
    # @.key - 50 == -100  →  key must be -50
    assert {:ok, [%{"key" => -50}]} ==
             JSONPathEx.evaluate("$[?(@.key - 50 == -100)]", data)
  end

  test "filter multiplication" do
    data = [%{"v" => 3}, %{"v" => 5}, %{"v" => 7}]
    assert {:ok, [%{"v" => 5}]} == JSONPathEx.evaluate("$[?(@.v * 2 == 10)]", data)
  end

  test "filter division" do
    data = [%{"v" => 10}, %{"v" => 8}, %{"v" => 5}]
    assert {:ok, [%{"v" => 10}]} == JSONPathEx.evaluate("$[?(@.v / 2 == 5)]", data)
  end

  test "filter modulo" do
    data = [%{"v" => 1}, %{"v" => 3}, %{"v" => 6}, %{"v" => 7}, %{"v" => 9}]
    assert {:ok, [%{"v" => 3}, %{"v" => 6}, %{"v" => 9}]} ==
             JSONPathEx.evaluate("$[?(@.v % 3 == 0)]", data)
  end

  test "filter arithmetic — multiplication before addition" do
    # @.v + 3 * 2 == 10  →  v + 6 == 10  →  v == 4
    data = [%{"v" => 4}, %{"v" => 2}, %{"v" => 10}]
    assert {:ok, [%{"v" => 4}]} ==
             JSONPathEx.evaluate("$[?(@.v + 3 * 2 == 10)]", data)
  end

  test "filter arithmetic — left-associative subtraction" do
    # @.v - 3 - 2 == 0  →  (v-3)-2 == 0  →  v == 5
    data = [%{"v" => 5}, %{"v" => 3}, %{"v" => 2}]
    assert {:ok, [%{"v" => 5}]} ==
             JSONPathEx.evaluate("$[?(@.v - 3 - 2 == 0)]", data)
  end

  test "filter arithmetic on missing key propagates nil" do
    # @.missing - 50 → nil; nil == -100 → false
    data = [%{"other" => 1}, %{"missing" => -50}]
    assert {:ok, [%{"missing" => -50}]} ==
             JSONPathEx.evaluate("$[?(@.missing - 50 == -100)]", data)
  end

  test "filter arithmetic — key-dash is a key name, not subtraction" do
    # @.key-50 (no spaces) is key "key-50", not @.key minus 50
    data = [%{"key" => -50}, %{"key-50" => -100}]
    assert {:ok, [%{"key-50" => -100}]} ==
             JSONPathEx.evaluate("$[?(@.key-50==-100)]", data)
  end

  # ---------------------------------------------------------------------------
  # 17.  Filters — root reference
  # ---------------------------------------------------------------------------
  test "filter with root reference" do
    # $.store.book[?(@.price <= $['expensive'])]
    assert {:ok,
            [
              %{"category" => "reference", "author" => "Nigel Rees", "title" => "Sayings of the Century", "price" => 8.95},
              %{"category" => "fiction", "author" => "Herman Melville", "title" => "Moby Dick", "isbn" => "0-553-21311-3", "price" => 8.99}
            ]} ==
             JSONPathEx.evaluate("$.store.book[?(@.price <= $['expensive'])]", @store)
  end

  # ---------------------------------------------------------------------------
  # 18.  Filters — nested dot path in operand
  # ---------------------------------------------------------------------------
  test "filter with nested path" do
    data = [
      %{"address" => %{"city" => "Berlin"}},
      %{"address" => %{"city" => "London"}}
    ]
    assert {:ok, [%{"address" => %{"city" => "Berlin"}}]} ==
             JSONPathEx.evaluate("$[?(@.address.city=='Berlin')]", data)
  end

  # ---------------------------------------------------------------------------
  # 19.  Shorthand filter syntax  [?expr]
  # ---------------------------------------------------------------------------
  test "shorthand filter without parens" do
    data = [%{"key" => 0}, %{"key" => 42}, %{"key" => 100}]
    assert {:ok, [%{"key" => 42}]} == JSONPathEx.evaluate("$[?@.key==42]", data)
  end

  test "shorthand existence filter" do
    data = [%{"a" => 1}, %{"b" => 2}, %{"a" => 3}]
    assert {:ok, [%{"a" => 1}, %{"a" => 3}]} == JSONPathEx.evaluate("$[?@.a]", data)
  end

  # ---------------------------------------------------------------------------
  # 20.  Filter on map root (converts to values)
  # ---------------------------------------------------------------------------
  test "filter applied to map iterates over values" do
    data = %{"a" => %{"v" => 0}, "b" => %{"v" => 5}, "c" => %{"v" => 3}}
    assert {:ok, result} = JSONPathEx.evaluate("$[?(@.v > 2)]", data)
    assert %{"v" => 5} in result
    assert %{"v" => 3} in result
    assert length(result) == 2
  end

  # ---------------------------------------------------------------------------
  # 21.  Built-in functions
  # ---------------------------------------------------------------------------
  test "length function" do
    assert {:ok, 3} == JSONPathEx.evaluate("$.items.length()", %{"items" => ["a", "b", "c"]})
    assert {:ok, 0} == JSONPathEx.evaluate("$.items.length()", %{"items" => []})
  end

  test "sum function" do
    assert {:ok, 60} == JSONPathEx.evaluate("$.items.sum()", %{"items" => [10, 20, 30]})
    assert {:ok, 0} == JSONPathEx.evaluate("$.items.sum()", %{"items" => []})
  end

  test "min function" do
    assert {:ok, 10} == JSONPathEx.evaluate("$.items.min()", %{"items" => [10, 20, 30]})
  end

  test "max function" do
    assert {:ok, 30} == JSONPathEx.evaluate("$.items.max()", %{"items" => [10, 20, 30]})
  end

  test "avg function" do
    assert {:ok, 20.0} == JSONPathEx.evaluate("$.items.avg()", %{"items" => [10, 20, 30]})
    assert {:ok, nil} == JSONPathEx.evaluate("$.items.avg()", %{"items" => []})
  end

  test "concat function" do
    assert {:ok, "abc"} == JSONPathEx.evaluate("$.items.concat()", %{"items" => ["a", "b", "c"]})
    assert {:ok, ""} == JSONPathEx.evaluate("$.items.concat()", %{"items" => []})
    assert {:ok, "123"} == JSONPathEx.evaluate("$.items.concat()", %{"items" => [1, 2, 3]})
  end

  # ---------------------------------------------------------------------------
  # 22.  Classic bookstore smoke tests
  # ---------------------------------------------------------------------------
  test "bookstore — all authors" do
    assert {:ok, ["Nigel Rees", "Evelyn Waugh", "Herman Melville", "J. R. R. Tolkien"]} ==
             JSONPathEx.evaluate("$.store.book[*].author", @store)
  end

  test "bookstore — all authors via deep scan" do
    assert {:ok, ["Nigel Rees", "Evelyn Waugh", "Herman Melville", "J. R. R. Tolkien"]} ==
             JSONPathEx.evaluate("$..author", @store)
  end

  test "bookstore — all prices (map-order independent)" do
    assert {:ok, prices} = JSONPathEx.evaluate("$.store..price", @store)
    assert Enum.sort(prices) == Enum.sort([19.95, 8.95, 12.99, 8.99, 22.99])
  end

  test "bookstore — store wildcard contains bicycle and book" do
    assert {:ok, result} = JSONPathEx.evaluate("$.store.*", @store)
    assert length(result) == 2
    assert %{"color" => "red", "price" => 19.95} in result
    book_array = @store |> Map.get("store") |> Map.get("book")
    assert book_array in result
  end

  test "bookstore — third book" do
    assert {:ok,
            [
              %{
                "category" => "fiction",
                "author" => "Herman Melville",
                "title" => "Moby Dick",
                "isbn" => "0-553-21311-3",
                "price" => 8.99
              }
            ]} == JSONPathEx.evaluate("$..book[2]", @store)
  end

  test "bookstore — second-to-last book" do
    assert {:ok,
            [
              %{
                "category" => "fiction",
                "author" => "Herman Melville",
                "title" => "Moby Dick",
                "isbn" => "0-553-21311-3",
                "price" => 8.99
              }
            ]} == JSONPathEx.evaluate("$..book[-2]", @store)
  end

  test "bookstore — first two books" do
    assert {:ok, [first, second]} = JSONPathEx.evaluate("$..book[0,1]", @store)
    assert first["author"] == "Nigel Rees"
    assert second["author"] == "Evelyn Waugh"
  end

  test "bookstore — slice [:2]" do
    assert {:ok, [first, second]} = JSONPathEx.evaluate("$..book[:2]", @store)
    assert first["title"] == "Sayings of the Century"
    assert second["title"] == "Sword of Honour"
  end

  test "bookstore — slice [1:2]" do
    assert {:ok, [book]} = JSONPathEx.evaluate("$..book[1:2]", @store)
    assert book["title"] == "Sword of Honour"
  end

  test "bookstore — slice [-2:]" do
    assert {:ok, [third, fourth]} = JSONPathEx.evaluate("$..book[-2:]", @store)
    assert third["title"] == "Moby Dick"
    assert fourth["title"] == "The Lord of the Rings"
  end

  test "bookstore — slice [2:]" do
    assert {:ok, [third, fourth]} = JSONPathEx.evaluate("$..book[2:]", @store)
    assert third["title"] == "Moby Dick"
    assert fourth["title"] == "The Lord of the Rings"
  end

  test "bookstore — books with isbn" do
    assert {:ok, [moby, lotr]} = JSONPathEx.evaluate("$..book[?(@.isbn)]", @store)
    assert moby["title"] == "Moby Dick"
    assert lotr["title"] == "The Lord of the Rings"
  end

  test "bookstore — books under 10" do
    assert {:ok, [rees, melville]} =
             JSONPathEx.evaluate("$.store.book[?(@.price < 10)]", @store)
    assert rees["author"] == "Nigel Rees"
    assert melville["author"] == "Herman Melville"
  end

  test "bookstore — book count via deep scan + function" do
    assert {:ok, [4]} == JSONPathEx.evaluate("$..book.length()", @store)
  end

  # ---------------------------------------------------------------------------
  # 23.  Key access on non-map list elements
  # ---------------------------------------------------------------------------
  test "key access on list of scalars returns empty" do
    assert {:ok, []} ==
             JSONPathEx.evaluate("$.items.name", %{"items" => [1, "two", nil, true]})
  end

  # ---------------------------------------------------------------------------
  # 24.  Escape sequences in quoted keys
  # ---------------------------------------------------------------------------
  test "escape sequences in single-quoted bracket keys" do
    data = %{"it's" => 1, "back\\slash" => 2, "tab\there" => 3}
    assert {:ok, 1} == JSONPathEx.evaluate("$['it\\'s']", data)
    assert {:ok, 2} == JSONPathEx.evaluate("$['back\\\\slash']", data)
  end

  test "escape sequences in double-quoted bracket keys" do
    data = %{"quo\"ted" => 42, "line\\end" => 99}
    assert {:ok, 42} == JSONPathEx.evaluate("$[\"quo\\\"ted\"]", data)
    assert {:ok, 99} == JSONPathEx.evaluate("$[\"line\\\\end\"]", data)
  end

  test "escaped key in filter comparison" do
    items = [%{"it's" => true, "name" => "A"}, %{"it's" => false, "name" => "B"}]
    assert {:ok, [%{"it's" => true, "name" => "A"}]} ==
             JSONPathEx.evaluate("$[?(@['it\\'s'] == true)]", items)
  end

  # ---------------------------------------------------------------------------
  # 25.  Quoted dot-child  $."key"  $.'key'
  # ---------------------------------------------------------------------------
  test "quoted dot-child single and double" do
    data = %{"store" => %{"book" => [1, 2]}}
    assert {:ok, %{"book" => [1, 2]}} == JSONPathEx.evaluate("$.'store'", data)
    assert {:ok, %{"book" => [1, 2]}} == JSONPathEx.evaluate("$.\"store\"", data)
  end

  test "quoted dot-child with spaces and special chars" do
    data = %{"key with spaces" => "found", "key-dash" => "dash"}
    assert {:ok, "found"} == JSONPathEx.evaluate("$.\"key with spaces\"", data)
    assert {:ok, "dash"} == JSONPathEx.evaluate("$.'key-dash'", data)
  end

  test "deep-scan quoted dot-child" do
    data = %{"a" => %{"target" => 1}, "b" => %{"target" => 2}}
    result = JSONPathEx.evaluate("$..'target'", data)
    assert {:ok, targets} = result
    assert Enum.sort(targets) == [1, 2]
  end

  # ---------------------------------------------------------------------------
  # 26.  Dollar sign as dot-child key  $.$
  # ---------------------------------------------------------------------------
  test "dollar sign as key name" do
    data = %{"$" => "root-value", "nested" => %{"$" => "inner"}}
    assert {:ok, "root-value"} == JSONPathEx.evaluate("$.$", data)
    assert {:ok, "inner"} == JSONPathEx.evaluate("$.nested.$", data)
  end

  # ---------------------------------------------------------------------------
  # 27.  Nested filters  $[?(@.arr[?(@.x > N)])]
  # ---------------------------------------------------------------------------
  test "nested filter — existence check on inner filtered array" do
    data = [
      %{"name" => "A", "tags" => [%{"name" => "important"}, %{"name" => "other"}]},
      %{"name" => "B", "tags" => [%{"name" => "other"}]},
      %{"name" => "C", "tags" => []}
    ]
    # Only "A" has a tag with name == "important"
    assert {:ok, [%{"name" => "A", "tags" => [%{"name" => "important"}, %{"name" => "other"}]}]} ==
             JSONPathEx.evaluate("$[?(@.tags[?(@.name == \"important\")])]", data)
  end

  test "nested filter — numeric comparison inside inner filter" do
    data = [
      %{"id" => 1, "scores" => [%{"val" => 90}, %{"val" => 50}]},
      %{"id" => 2, "scores" => [%{"val" => 30}, %{"val" => 20}]},
      %{"id" => 3, "scores" => [%{"val" => 80}]}
    ]
    # Items where at least one score > 70
    assert {:ok, [%{"id" => 1, "scores" => [%{"val" => 90}, %{"val" => 50}]},
                  %{"id" => 3, "scores" => [%{"val" => 80}]}]} ==
             JSONPathEx.evaluate("$[?(@.scores[?(@.val > 70)])]", data)
  end

  test "nested filter — no matches yields empty" do
    data = [
      %{"name" => "X", "items" => [%{"active" => false}]},
      %{"name" => "Y", "items" => [%{"active" => false}]}
    ]
    assert {:ok, []} ==
             JSONPathEx.evaluate("$[?(@.items[?(@.active == true)])]", data)
  end

  # ---------------------------------------------------------------------------
  # 28.  Root reference with array index in filter  $.path[N]
  # ---------------------------------------------------------------------------
  test "root reference with array index in filter" do
    data = %{
      "threshold" => [100, 200],
      "items" => [%{"val" => 50}, %{"val" => 150}, %{"val" => 250}]
    }
    # Compare each item's val to $.threshold[0] (which is 100)
    assert {:ok, [%{"val" => 150}, %{"val" => 250}]} ==
             JSONPathEx.evaluate("$.items[?(@.val > $.threshold[0])]", data)
  end

  # ---------------------------------------------------------------------------
  # 29.  Invalid expressions → error tuple
  # ---------------------------------------------------------------------------
  test "returns error for unparseable expressions" do
    assert {:error, _} = JSONPathEx.evaluate("$.invalid[", %{})
    assert {:error, _} = JSONPathEx.evaluate("not-jsonpath", %{})
    assert {:error, _} = JSONPathEx.evaluate("", %{})
  end
end

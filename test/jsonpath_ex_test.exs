defmodule JJSONPathExTest do
  use ExUnit.Case
  doctest JSONPathEx

  @example %{
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
      "bicycle" => %{
        "color" => "red",
        "price" => 19.95
      }
    },
    "expensive" => 10
  }

  test "evaluates JSONPath expression" do
    assert {:ok, ["Nigel Rees", "Evelyn Waugh", "Herman Melville", "J. R. R. Tolkien"]} ==
             JSONPathEx.evaluate("$.store.book[*].author", @example)

    assert {:ok, ["Nigel Rees", "Evelyn Waugh", "Herman Melville", "J. R. R. Tolkien"]} ==
             JSONPathEx.evaluate("$..author", @example)

    # this is not correct
    assert {:ok,
            %{
              "bicycle" => %{"color" => "red", "price" => 19.95},
              "book" => [
                %{
                  "author" => "Nigel Rees",
                  "category" => "reference",
                  "price" => 8.95,
                  "title" => "Sayings of the Century"
                },
                %{
                  "author" => "Evelyn Waugh",
                  "category" => "fiction",
                  "price" => 12.99,
                  "title" => "Sword of Honour"
                },
                %{
                  "author" => "Herman Melville",
                  "category" => "fiction",
                  "isbn" => "0-553-21311-3",
                  "price" => 8.99,
                  "title" => "Moby Dick"
                },
                %{
                  "author" => "J. R. R. Tolkien",
                  "category" => "fiction",
                  "isbn" => "0-395-19395-8",
                  "price" => 22.99,
                  "title" => "The Lord of the Rings"
                }
              ]
            }} == JSONPathEx.evaluate("$.store.*", @example)

    assert {:ok, [8.95, 12.99, 8.99, 22.99, 19.95]} ==
             JSONPathEx.evaluate("$.store..price", @example)

    assert {:ok,
            [
              %{
                "author" => "Herman Melville",
                "category" => "fiction",
                "isbn" => "0-553-21311-3",
                "price" => 8.99,
                "title" => "Moby Dick"
              }
            ]} == JSONPathEx.evaluate("$..book[2]", @example)

    assert {:ok,
            [
              %{
                "author" => "Herman Melville",
                "category" => "fiction",
                "isbn" => "0-553-21311-3",
                "price" => 8.99,
                "title" => "Moby Dick"
              }
            ]} == JSONPathEx.evaluate("$..book[-2]", @example)

    assert {:ok,
            [
              %{
                "author" => "Nigel Rees",
                "category" => "reference",
                "price" => 8.95,
                "title" => "Sayings of the Century"
              },
              %{
                "author" => "Evelyn Waugh",
                "category" => "fiction",
                "price" => 12.99,
                "title" => "Sword of Honour"
              }
            ]} == JSONPathEx.evaluate("$..book[0,1]", @example)

    assert {:ok,
            [
              %{
                "author" => "Nigel Rees",
                "category" => "reference",
                "price" => 8.95,
                "title" => "Sayings of the Century"
              },
              %{
                "author" => "Evelyn Waugh",
                "category" => "fiction",
                "price" => 12.99,
                "title" => "Sword of Honour"
              }
            ]} == JSONPathEx.evaluate("$..book[:2]", @example)

    assert {:ok,
            [
              %{
                "author" => "Evelyn Waugh",
                "category" => "fiction",
                "price" => 12.99,
                "title" => "Sword of Honour"
              }
            ]} == JSONPathEx.evaluate("$..book[1:2]", @example)

    assert {:ok,
            [
              %{
                "author" => "Herman Melville",
                "category" => "fiction",
                "isbn" => "0-553-21311-3",
                "price" => 8.99,
                "title" => "Moby Dick"
              },
              %{
                "author" => "J. R. R. Tolkien",
                "category" => "fiction",
                "isbn" => "0-395-19395-8",
                "price" => 22.99,
                "title" => "The Lord of the Rings"
              }
            ]} == JSONPathEx.evaluate("$..book[-2:]", @example)

    assert {:ok,
            [
              %{
                "author" => "Herman Melville",
                "category" => "fiction",
                "isbn" => "0-553-21311-3",
                "price" => 8.99,
                "title" => "Moby Dick"
              },
              %{
                "author" => "J. R. R. Tolkien",
                "category" => "fiction",
                "isbn" => "0-395-19395-8",
                "price" => 22.99,
                "title" => "The Lord of the Rings"
              }
            ]} == JSONPathEx.evaluate("$..book[2:]", @example)

    assert {:ok,
            [
              %{
                "author" => "Herman Melville",
                "category" => "fiction",
                "isbn" => "0-553-21311-3",
                "price" => 8.99,
                "title" => "Moby Dick"
              },
              %{
                "author" => "J. R. R. Tolkien",
                "category" => "fiction",
                "isbn" => "0-395-19395-8",
                "price" => 22.99,
                "title" => "The Lord of the Rings"
              }
            ]} == JSONPathEx.evaluate("$..book[?(@.isbn)]", @example)

    assert {:ok,
            [
              %{
                "author" => "Nigel Rees",
                "category" => "reference",
                "price" => 8.95,
                "title" => "Sayings of the Century"
              },
              %{
                "author" => "Herman Melville",
                "category" => "fiction",
                "isbn" => "0-553-21311-3",
                "price" => 8.99,
                "title" => "Moby Dick"
              }
            ]} == JSONPathEx.evaluate("$.store.book[?(@.price < 10)]", @example)

    assert {:ok,
            [
              %{
                "author" => "Nigel Rees",
                "category" => "reference",
                "price" => 8.95,
                "title" => "Sayings of the Century"
              },
              %{
                "author" => "Herman Melville",
                "category" => "fiction",
                "isbn" => "0-553-21311-3",
                "price" => 8.99,
                "title" => "Moby Dick"
              }
            ]} == JSONPathEx.evaluate("$..book[?(@.price <= $['expensive'])]", @example)

    assert {:ok,
            ["value", %{"complex" => "string", "primitives" => [0, 1]}, [0, 1], "string", 1, 0]} ==
             JSONPathEx.evaluate("$..*", %{
               "key" => "value",
               "another key" => %{
                 "complex" => "string",
                 "primitives" => [0, 1]
               }
             })

    assert {:ok, 4} == JSONPathEx.evaluate("$..book.length()", @example)
    # assert {:ok, []} == JSONPathEx.evaluate("$..book[?(@.author =~ /.*REES/i)]", @example)
  end
end

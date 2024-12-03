alias JSONPathEx.{Parser, Evaluator}

example = %{
    "store" => %{
      "book" => [
        %{
          "category" => "reference",
          "author" => "Nigel Rees",
          "title" => "Sayings of the Century",
          "price" => 8.95,
          "a_list" => [1]
        },
        %{
          "category" => "fiction",
          "author" => "Evelyn Waugh",
          "title" => "Sword of Honour",
          "price" => 12.99,
          "a_list" => [2, 3]
        },
        %{
          "category" => "fiction",
          "author" => "Herman Melville",
          "title" => "Moby Dick",
          "isbn" => "0-553-21311-3",
          "price" => 8.99,
          "a_list" => [4, 5, 6]
        },
        %{
          "category" => "fiction",
          "author" => "J. R. R. Tolkien",
          "title" => "The Lord of the Rings",
          "isbn" => "0-395-19395-8",
          "price" => 22.99,
          "a_list" => [7, 8, 9, 10]
        }
      ],
      "bicycle" => %{
        "color" => "red",
        "price" => 19.95
      }
    },
    "expensive" => 10
  }

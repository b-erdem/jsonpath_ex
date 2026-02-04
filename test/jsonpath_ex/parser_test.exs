defmodule JSONPathEx.ParserTest do
  use ExUnit.Case

  alias JSONPathEx.Parser

  # ---------------------------------------------------------------------------
  # Slices — all valid slice forms
  # ---------------------------------------------------------------------------
  test "parses slice expressions" do
    slices = [
      "$[1:3]", "$[0:5]", "$[7:10]", "$[1:10]",
      "$[2:113667776004]", "$[2:-113667776004:-1]",
      "$[-113667776004:2]", "$[113667776004:2:-1]",
      "$[-4:-5]", "$[-4:-4]", "$[-4:-3]",
      "$[-4:1]", "$[-4:2]", "$[-4:3]",
      "$[3:0:-2]", "$[7:3:-1]", "$[0:3:-2]",
      "$[::-2]", "$[1:]", "$[3::-1]", "$[:2]",
      "$[:]", "$[::]", "$[:2:-1]",
      "$[3:-4]", "$[3:-3]", "$[3:-2]",
      "$[2:1]", "$[0:0]", "$[0:1]",
      "$[-1:]", "$[-2:]", "$[-4:]",
      "$[0:3:2]", "$[0:3:0]", "$[0:3:1]",
      "$[010:024:010]", "$[0:4:2]",
      "$[1:3:]", "$[::2]"
    ]
    Enum.each(slices, fn expr -> assert {:ok, _} = Parser.parse(expr), expr end)
  end

  # ---------------------------------------------------------------------------
  # Bracket-notated keys — including special characters
  # ---------------------------------------------------------------------------
  test "parses bracket keys" do
    keys = [
      "$['key']", "$['missing']", "$['two.some']", "$[\"key\"]",
      "$['']", "$[\"\"]",                      # empty string keys
      "$[':']", "$[']']", "$['@']", "$['.']",  # punctuation
      "$['.*']", "$['\"']", "$['*']",          # glob-like content
      "$['0']", "$['$']", "$[',']",            # digits and sigils
      "$[ 'a' ]",                              # whitespace tolerance
      "$['ni.*']", "$['key with spaces']",     # spaces / globs
      "$['ü']",                                # unicode
      "$[two.some]", "$[key]",                 # unquoted (field_name)
      "$['it\\'s']", "$['back\\\\slash']",     # escape sequences
      "$[\"quo\\\"ted\"]"                      # escaped double-quote
    ]
    Enum.each(keys, fn expr -> assert {:ok, _} = Parser.parse(expr), expr end)
  end

  # ---------------------------------------------------------------------------
  # Array indices and multi-index
  # ---------------------------------------------------------------------------
  test "parses array indices" do
    indices = [
      "$[-2]", "$[2]", "$[0]", "$[1]", "$[-1]",
      "$[0,1]", "$[0,0]", "$[4,1]",
      "$[ 0 , 1 ]",                            # whitespace tolerance
      "$['a','a']", "$['key','another']", "$['missing','key']",
      "$[:]['c','d']", "$[0]['c','d']", "$.*['c','d']", "$..['c','d']"
    ]
    Enum.each(indices, fn expr -> assert {:ok, _} = Parser.parse(expr), expr end)
  end

  # ---------------------------------------------------------------------------
  # Wildcards and deep scan
  # ---------------------------------------------------------------------------
  test "parses wildcards and deep scan" do
    exprs = [
      "$[*]", "$[0:2][*]", "$[*].bar[*]", "$..[*]",
      "$.*", "$.*.bar.*", "$.*.*", "$..*",
      "$..*[?(@.id>2)]", "$..[?(@.id==2)]",
      "$.*[1]", "$.*[?(@.key)]",
      "$..", "$..*", "$.key.."
    ]
    Enum.each(exprs, fn expr -> assert {:ok, _} = Parser.parse(expr), expr end)
  end

  # ---------------------------------------------------------------------------
  # Dot-notated keys — including keyword-like names
  # ---------------------------------------------------------------------------
  test "parses dot children" do
    exprs = [
      "$.key", "$.id", "$[0:2].key", "$..[1].key",
      "$[*].a", "$[0,2].key", "$['one','three'].key",
      "$.key-dash",     # hyphen in key
      "$.in",           # reserved word as key
      "$.length",       # function name as key
      "$.null",         # null as key name
      "$.true",         # true as key name
      "$.2",            # numeric key
      "$.-1",           # hyphen-numeric key
      "$.$",            # dollar sign as key
      "$.\"key\"",      # double-quoted dot-child
      "$.'key'",        # single-quoted dot-child
      "$.\"key with spaces\"",  # quoted with spaces
      "$..'key'",       # deep-scan single-quoted
      "$..\"key\""      # deep-scan double-quoted
    ]
    Enum.each(exprs, fn expr -> assert {:ok, _} = Parser.parse(expr), expr end)
  end

  # ---------------------------------------------------------------------------
  # Dot + bracket hybrid
  # ---------------------------------------------------------------------------
  test "parses dot-bracket hybrids" do
    exprs = [
      "$.['key']", "$.[ \"key\" ]", "$.[key]",
      "$...key"   # triple-dot normalises to deep scan + key
    ]
    Enum.each(exprs, fn expr -> assert {:ok, _} = Parser.parse(expr), expr end)
  end

  # ---------------------------------------------------------------------------
  # Deep-scan key + chained selectors
  # ---------------------------------------------------------------------------
  test "parses deep-scan + chained selectors" do
    exprs = [
      "$.store..price",
      "$..key",
      "$..['c','d']",
      "$[?(@.id==42)].name",
      "$.items[?(@.key==$.value)]"
    ]
    Enum.each(exprs, fn expr -> assert {:ok, _} = Parser.parse(expr), expr end)
  end

  # ---------------------------------------------------------------------------
  # Functions
  # ---------------------------------------------------------------------------
  test "parses function calls" do
    exprs = [
      "$.data.sum()",
      "$.data.length()",
      "$.data.min()",
      "$.data.max()",
      "$.data.avg()",
      "$.data.concat()"
    ]
    Enum.each(exprs, fn expr -> assert {:ok, _} = Parser.parse(expr), expr end)
  end

  # ---------------------------------------------------------------------------
  # Filters — operators, logic, arithmetic, grouping
  # ---------------------------------------------------------------------------
  test "parses filter expressions" do
    exprs = [
      # existence
      "$[?(@.key)]", "$[?(!@.key)]", "$[?(@)]",
      # comparison
      "$[?(@.key==42)]", "$[?(@.key!=42)]",
      "$[?(@.key>42)]", "$[?(@.key>=42)]",
      "$[?(@.key<42)]", "$[?(@.key<=42)]",
      "$[?(@.key===42)]",
      "$[?(@.key==true)]", "$[?(@.key==false)]", "$[?(@.key==null)]",
      "$[?(@.key==\"value\")]", "$[?(@.key=='value')]",
      "$[?(@.key==\"hi@example.com\")]", "$[?(@.key==\"some.value\")]",
      "$[?(@.key==\"Motörhead\")]",
      "$[?(@.key>\"VALUE\")]",
      "$[?(@.key==010)]",
      # logical
      "$[?(@.key>42 && @.key<44)]",
      "$[?(@.key>0 && false)]", "$[?(@.key>0 && true)]",
      "$[?(@.key>43 || @.key<43)]",
      "$[?(@.key>0 || false)]", "$[?(@.key>0 || true)]",
      "$[?(@.a && (@.b || @.c))]",
      "$[?(@.a && @.b || @.c)]",
      # negated grouping
      "$[?(!(@.key==42))]", "$[?(!(@.key<42))]",
      "$[?(!(@.d==[\"v1\",\"v2\"]) || (@.d == true))]",
      # arithmetic
      "$[?(@.key+50==100)]", "$[?(@.key-50==-100)]",
      "$[?(@.key/10==5)]", "$[?(@.key*2==100)]",
      # in / nin
      "$[?(@.d in [2, 3])]", "$[?(2 in @.d)]",
      # list comparison
      "$[?(@.d==[\"v1\",\"v2\"])]", "$[?(@.d==['v1','v2'])]",
      "$[?(@[0:1]==[1])]", "$[?(@.*==[1,2])]",
      "$[?(@.d==[\"v1\",\"v2\"] || (@.d == true))]",
      "$[?((@.d!=[\"v1\",\"v2\"]) || (@.d == true))]",
      # bracket path in filter
      "$[?(@['key']==42)]", "$[?(@['@key']==42)]",
      "$[?(@[-1]==2)]", "$[?(@[1]=='b')]",
      "$[?(@[0:1]==1)]", "$[?(@[*]==2)]", "$[?(@.*==2)]",
      # key with dash (parsed as key name, not subtraction)
      "$[?(@.key-dash == 'value')]",
      # numeric-start key in filter path
      "$[?(@.2 == 'second')]",
      # nested dot path
      "$[?(@.address.city=='Berlin')]",
      # root reference in filter
      "$.items[?(@.key==$.value)]",
      # cross-context comparison
      "$[?(@.key1==@.key2)]",
      # boolean / null literals
      "$[?((@.key<44)==false)]",
      # grouping with comparison result
      "$[?(1==1)]",
      # deep scan inside filter operand
      "$[?(@..child)]",
      # bare boolean / null filter
      "$[?(true)]", "$[?(false)]", "$[?(null)]",
      # shorthand filter (no parens)
      "$[?@.key==42]",
      # function in filter
      "$[?(@.length() == 4)]",
      # length as key (not function)
      "$[?(@.length == 4)]",
      # chained after filter
      "$[?(@.id==42)].name",
      "$[*].bookmarks[?(@.page == 45)]",
      # nested filter (filter inside a filter operand path)
      "$[?(@.tags[?(@.name == \"important\")])]",
      "$[?(@.items[?(@.price > 10)])]",
      # root ref with array wildcard in filter operand (valid since root_key supports arrays)
      "$.x[?(@[*]>=$.y[*])]"
    ]
    Enum.each(exprs, fn expr -> assert {:ok, _} = Parser.parse(expr), expr end)
  end

  # ---------------------------------------------------------------------------
  # Expressions that are deliberately invalid / unsupported → must error
  # ---------------------------------------------------------------------------
  test "rejects invalid expressions" do
    invalid = [
      # no root selector
      ".key", "key", "$a",
      # empty brackets
      "$[]",
      # space after dot (no whitespace tolerance in dot-child)
      "$. a",
      # computed array index not supported
      "$[(@.length-1)]",
      # multiple comma-separated filters not supported
      "$[?(@.key<3),?(@.key>6)]",
      # mixed slice+index / wildcard+index in one bracket
      "$[1:3,4]", "$.*[0,:5]", "$[*,1]",
      # single = (assignment, not comparison)
      "$[?(@.key='value')]", "$[?(@.key=42)]",

      # ---------------------------------------------------------------------------
      # Valid RFC 9535 — not yet supported by this parser
      # ---------------------------------------------------------------------------
      "$.屬性",                  # unicode member names in dot notation
      "$[?(@.key==-0.123e2)]",  # scientific-notation floats
      "$[?(length(@) == 4)]"    # prefix-style function calls
    ]
    Enum.each(invalid, fn expr ->
      assert {:error, _} = Parser.parse(expr), "expected error for: #{expr}"
    end)
  end
end

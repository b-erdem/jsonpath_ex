defmodule JsonpathEx.ParserTest do
  use ExUnit.Case
  # doctest JsonpathEx

  alias JsonpathEx.Parser

  test "parses jsonpath expressions" do
    assert {:ok, _parsed} = Parser.parse("$[1:3]")
    assert {:ok, _parsed} = Parser.parse("$[0:5]")
    assert {:ok, _parsed} = Parser.parse("$[7:10]")
    assert {:ok, _parsed} = Parser.parse("$[1:3]")
    assert {:ok, _parsed} = Parser.parse("$[1:10]")
    assert {:ok, _parsed} = Parser.parse("$[2:113667776004]")
    assert {:ok, _parsed} = Parser.parse("$[2:-113667776004:-1]")
    assert {:ok, _parsed} = Parser.parse("$[-113667776004:2]")
    assert {:ok, _parsed} = Parser.parse("$[113667776004:2:-1]")
    assert {:ok, _parsed} = Parser.parse("$[-4:-5]")
    assert {:ok, _parsed} = Parser.parse("$[-4:-4]")
    assert {:ok, _parsed} = Parser.parse("$[-4:-3]")
    assert {:ok, _parsed} = Parser.parse("$[-4:1]")
    assert {:ok, _parsed} = Parser.parse("$[-4:2]")
    assert {:ok, _parsed} = Parser.parse("$[-4:3]")
    assert {:ok, _parsed} = Parser.parse("$[3:0:-2]")
    assert {:ok, _parsed} = Parser.parse("$[7:3:-1]")
    assert {:ok, _parsed} = Parser.parse("$[0:3:-2]")
    assert {:ok, _parsed} = Parser.parse("$[::-2]")
    assert {:ok, _parsed} = Parser.parse("$[1:]")
    assert {:ok, _parsed} = Parser.parse("$[3::-1]")
    assert {:ok, _parsed} = Parser.parse("$[:2]")
    assert {:ok, _parsed} = Parser.parse("$[:]")
    assert {:ok, _parsed} = Parser.parse("$[:]")
    assert {:ok, _parsed} = Parser.parse("$[::]")
    assert {:ok, _parsed} = Parser.parse("$[:2:-1]")
    assert {:ok, _parsed} = Parser.parse("$[3:-4]")
    assert {:ok, _parsed} = Parser.parse("$[3:-3]")
    assert {:ok, _parsed} = Parser.parse("$[3:-2]")
    assert {:ok, _parsed} = Parser.parse("$[2:1]")
    assert {:ok, _parsed} = Parser.parse("$[0:0]")
    assert {:ok, _parsed} = Parser.parse("$[0:1]")
    assert {:ok, _parsed} = Parser.parse("$[-1:]")
    assert {:ok, _parsed} = Parser.parse("$[-2:]")
    assert {:ok, _parsed} = Parser.parse("$[-4:]")
    assert {:ok, _parsed} = Parser.parse("$[0:3:2]")
    assert {:ok, _parsed} = Parser.parse("$[0:3:0]")
    assert {:ok, _parsed} = Parser.parse("$[0:3:1]")
    assert {:ok, _parsed} = Parser.parse("$[010:024:010]")
    assert {:ok, _parsed} = Parser.parse("$[0:4:2]")
    assert {:ok, _parsed} = Parser.parse("$[1:3:]")
    assert {:ok, _parsed} = Parser.parse("$[::2]")
    assert {:ok, _parsed} = Parser.parse("$['key']")
    assert {:ok, _parsed} = Parser.parse("$['missing']")
    assert {:ok, _parsed} = Parser.parse("$..[0]")
    # assert {:ok, _parsed} = Parser.parse("$['ü']")
    assert {:ok, _parsed} = Parser.parse("$['two.some']")
    assert {:ok, _parsed} = Parser.parse("$[\"key\"]")
    # assert {:ok, _parsed} = Parser.parse("$[]")
    # assert {:ok, _parsed} = Parser.parse("$['']")
    # assert {:ok, _parsed} = Parser.parse("$[\"\"]")
    assert {:ok, _parsed} = Parser.parse("$[-2]")
    assert {:ok, _parsed} = Parser.parse("$[2]")
    assert {:ok, _parsed} = Parser.parse("$[0]")
    assert {:ok, _parsed} = Parser.parse("$[1]")
    assert {:ok, _parsed} = Parser.parse("$[1]")
    # assert {:ok, _parsed} = Parser.parse("$.*[1]")
    assert {:ok, _parsed} = Parser.parse("$[-1]")
    # assert {:ok, _parsed} = Parser.parse("$[':']")
    # assert {:ok, _parsed} = Parser.parse("$[']']")
    assert {:ok, _parsed} = Parser.parse("$['@']")
    assert {:ok, _parsed} = Parser.parse("$['.']")
    # assert {:ok, _parsed} = Parser.parse("$['.*']")
    # assert {:ok, _parsed} = Parser.parse("$['\"']")
    # assert {:ok, _parsed} = Parser.parse("$['*']")
    # assert {:ok, _parsed} = Parser.parse("$['\\']")
    # assert {:ok, _parsed} = Parser.parse("$['\'']")
    assert {:ok, _parsed} = Parser.parse("$['0']")
    # assert {:ok, _parsed} = Parser.parse("$['$']")
    # assert {:ok, _parsed} = Parser.parse("$[':@.\"$,*\'\\']")
    # assert {:ok, _parsed} = Parser.parse("$['single'quote']")
    # assert {:ok, _parsed} = Parser.parse("$[',']")
    # assert {:ok, _parsed} = Parser.parse("$[ 'a' ]")
    # assert {:ok, _parsed} = Parser.parse("$['ni.*']")
    # assert {:ok, _parsed} = Parser.parse("$['two'.'some']")
    assert {:ok, _parsed} = Parser.parse("$[two.some]")
    assert {:ok, _parsed} = Parser.parse("$[*]")
    assert {:ok, _parsed} = Parser.parse("$[0:2][*]")
    assert {:ok, _parsed} = Parser.parse("$[*].bar[*]")
    assert {:ok, _parsed} = Parser.parse("$..[*]")
    assert {:ok, _parsed} = Parser.parse("$[key]")
    # assert {:ok, _parsed} = Parser.parse("@.a")
    assert {:ok, _parsed} = Parser.parse("$.['key']")
    assert {:ok, _parsed} = Parser.parse("$.[\"key\"]")
    assert {:ok, _parsed} = Parser.parse("$.[key]")
    assert {:ok, _parsed} = Parser.parse("$.key")
    assert {:ok, _parsed} = Parser.parse("$.id")
    assert {:ok, _parsed} = Parser.parse("$[0:2].key")
    assert {:ok, _parsed} = Parser.parse("$..[1].key")
    assert {:ok, _parsed} = Parser.parse("$[*].a")
    assert {:ok, _parsed} = Parser.parse("$[?(@.id==42)].name")
    assert {:ok, _parsed} = Parser.parse("$..key")
    assert {:ok, _parsed} = Parser.parse("$.store..price")
    assert {:ok, _parsed} = Parser.parse("$...key")
    assert {:ok, _parsed} = Parser.parse("$[0,2].key")
    assert {:ok, _parsed} = Parser.parse("$['one','three'].key")
    assert {:ok, _parsed} = Parser.parse("$.key-dash")
    # assert {:ok, _parsed} = Parser.parse("$.\"key\"")
    # assert {:ok, _parsed} = Parser.parse("$..\"key\"")
    # assert {:ok, _parsed} = Parser.parse("$.")
    # assert {:ok, _parsed} = Parser.parse("$.in")
    # assert {:ok, _parsed} = Parser.parse("$.length")
    # assert {:ok, _parsed} = Parser.parse("$.null")
    # assert {:ok, _parsed} = Parser.parse("$.true")
    # assert {:ok, _parsed} = Parser.parse("$.$")
    # assert {:ok, _parsed} = Parser.parse("$.屬性")
    # assert {:ok, _parsed} = Parser.parse("$.2")
    # assert {:ok, _parsed} = Parser.parse("$.-1")
    # assert {:ok, _parsed} = Parser.parse("$.'key'")
    # assert {:ok, _parsed} = Parser.parse("$..'key'")
    # assert {:ok, _parsed} = Parser.parse("$. a")
    assert {:ok, _parsed} = Parser.parse("$.*")
    assert {:ok, _parsed} = Parser.parse("$.*.bar.*")
    assert {:ok, _parsed} = Parser.parse("$.*.*")
    assert {:ok, _parsed} = Parser.parse("$..*")
    # assert {:ok, _parsed} = Parser.parse("$a")
    # assert {:ok, _parsed} = Parser.parse(".key")
    # assert {:ok, _parsed} = Parser.parse("key")
    assert {:ok, _parsed} = Parser.parse("$[?(@.key)]")
    assert {:ok, _parsed} = Parser.parse("$..*[?(@.id>2)]")
    assert {:ok, _parsed} = Parser.parse("$..[?(@.id==2)]")
    assert {:ok, _parsed} = Parser.parse("$[?(@.key+50==100)]")
    assert {:ok, _parsed} = Parser.parse("$[?(@.key>42 && @.key<44)]")
    assert {:ok, _parsed} = Parser.parse("$[?(@.key>0 && false)]")
    assert {:ok, _parsed} = Parser.parse("$[?(@.key>0 && true)]")
    assert {:ok, _parsed} = Parser.parse("$[?(@.key>43 || @.key<43)]")
    assert {:ok, _parsed} = Parser.parse("$[?(@.key>0 || false)]")
    assert {:ok, _parsed} = Parser.parse("$[?(@.key>0 || true)]")
    assert {:ok, _parsed} = Parser.parse("$[?(@['key']==42)]")
    assert {:ok, _parsed} = Parser.parse("$[?(@['@key']==42)]")
    assert {:ok, _parsed} = Parser.parse("$[?(@[-1]==2)]")
    assert {:ok, _parsed} = Parser.parse("$[?(@[1]=='b')]")
    assert {:ok, _parsed} = Parser.parse("$[?(@)]")
    assert {:ok, _parsed} = Parser.parse("$[?(@.a && (@.b || @.c))]")
    assert {:ok, _parsed} = Parser.parse("$[?(@.a && @.b || @.c)]")
    assert {:ok, _parsed} = Parser.parse("$[?(@.key/10==5)]")
    assert {:ok, _parsed} = Parser.parse("$[?(@.key-dash == 'value')]")
    assert {:ok, _parsed} = Parser.parse("$[?(@.2 == 'second')]")
    assert {:ok, _parsed} = Parser.parse("$[?(@.key==42)]")
    assert {:ok, _parsed} = Parser.parse("$[?(@==42)]")
    assert {:ok, _parsed} = Parser.parse("$[?(@.id==2)]")
    assert {:ok, _parsed} = Parser.parse("$[?(@.d==[\"v1\",\"v2\"])]")
    assert {:ok, _parsed} = Parser.parse("$[?(@[0:1]==[1])]")
    assert {:ok, _parsed} = Parser.parse("$[?(@.*==[1,2])]")
    assert {:ok, _parsed} = Parser.parse("$[?(@.d==[\"v1\",\"v2\"] || (@.d == true))]")

    assert {:ok, _parsed} = Parser.parse("$[?(@.d==['v1','v2'])]")
    assert {:ok, _parsed} = Parser.parse("$[?((@.key<44)==false)]")
    assert {:ok, _parsed} = Parser.parse("$[?(@.key==false)]")
    assert {:ok, _parsed} = Parser.parse("$[?(@.key==null)]")
    assert {:ok, _parsed} = Parser.parse("$[?(@[0:1]==1)]")
    assert {:ok, _parsed} = Parser.parse("$[?(@[*]==2)]")
    assert {:ok, _parsed} = Parser.parse("$[?(@.*==2)]")
    # assert {:ok, _parsed} = Parser.parse("$[?(@.key==-0.123e2)]")
    assert {:ok, _parsed} = Parser.parse("$[?(@.key==010)]")
    # assert {:ok, _parsed} = Parser.parse("$[?(@.d=={\"k\":\"v\"})]")
    assert {:ok, _parsed} = Parser.parse("$[?(@.key==\"value\")]")
    # assert {:ok, _parsed} = Parser.parse("$[?()]")
    # assert {:ok, _parsed} = Parser.parse("$[?(@.key==\"Motörhead\")]")
    assert {:ok, _parsed} =
             Parser.parse("$[?(@.key==\"hi@example.com\")]")

    assert {:ok, _parsed} = Parser.parse("$[?(@.key==\"some.value\")]")
    assert {:ok, _parsed} = Parser.parse("$[?(@.key=='value')]")

    # assert {:ok, _parsed} = Parser.parse("$[?(@.key==\"Mot\u00f6rhead\")]")
    assert {:ok, _parsed} = Parser.parse("$[?(@.key==true)]")
    assert {:ok, _parsed} = Parser.parse("$[?(@.key1==@.key2)]")
    assert {:ok, _parsed} = Parser.parse("$.items[?(@.key==$.value)]")
    assert {:ok, _parsed} = Parser.parse("$[?(@.key>42)]")
    assert {:ok, _parsed} = Parser.parse("$[?(@.key>=42)]")
    assert {:ok, _parsed} = Parser.parse("$[?(@.key>\"VALUE\")]")
    assert {:ok, _parsed} = Parser.parse("$[?(@.d in [2, 3])]")
    assert {:ok, _parsed} = Parser.parse("$[?(2 in @.d)]")
    # assert {:ok, _parsed} = Parser.parse("$[?(length(@) == 4)]")
    assert {:ok, _parsed} = Parser.parse("$[?(@.length() == 4)]")
    assert {:ok, _parsed} = Parser.parse("$[?(@.length == 4)]")
    assert {:ok, _parsed} = Parser.parse("$[?(@.key<42)]")
    assert {:ok, _parsed} = Parser.parse("$[?(@.key<=42)]")
    # assert {:ok, _parsed} = Parser.parse("$[?(@.key='value')]")
    assert {:ok, _parsed} = Parser.parse("$[?(@.key*2==100)]")
    assert {:ok, _parsed} = Parser.parse("$[?(!(@.key==42))]")
    assert {:ok, _parsed} = Parser.parse("$[?(!(@.d==[\"v1\",\"v2\"]) || (@.d == true))]")
    assert {:ok, _parsed} = Parser.parse("$[?(!(@.key<42))]")
    assert {:ok, _parsed} = Parser.parse("$[?(!@.key)]")
    # assert {:ok, _parsed} = Parser.parse("$[?(@.a.*)]")
    assert {:ok, _parsed} = Parser.parse("$[?(@.key!=42)]")

    assert {:ok, _parsed} =
             Parser.parse("$[?((@.d!=[\"v1\",\"v2\"]) || (@.d == true))]")

    assert {:ok, _parsed} = Parser.parse("$[*].bookmarks[?(@.page == 45)]")
    # assert {:ok, _parsed} = Parser.parse("$[?(@.name=~/hello.*/)]")
    # assert {:ok, _parsed} = Parser.parse("$[?(@.name=~/@.pattern/)]")
    # assert {:ok, _parsed} = Parser.parse("$[?(@[*]>=4)]")
    # assert {:ok, _parsed} = Parser.parse("$.x[?(@[*]>=$.y[*])]")
    # assert {:ok, _parsed} = Parser.parse("$[?(@.key=42)]")
    # assert {:ok, _parsed} = Parser.parse("$[?(@.a[?(@.price>10)])]")

    assert {:ok, _parsed} =
             Parser.parse("$[?(@.address.city=='Berlin')]")

    assert {:ok, _parsed} = Parser.parse("$[?(@.key-50==-100)]")
    assert {:ok, _parsed} = Parser.parse("$[?(1==1)]")
    assert {:ok, _parsed} = Parser.parse("$[?(@.key===42)]")
    assert {:ok, _parsed} = Parser.parse("$[?(@.key)]")
    assert {:ok, _parsed} = Parser.parse("$.*[?(@.key)]")
    assert {:ok, _parsed} = Parser.parse("$..[?(@.id)]")
    assert {:ok, _parsed} = Parser.parse("$[?(false)]")
    assert {:ok, _parsed} = Parser.parse("$[?(@..child)]")
    # assert {:ok, _parsed} = Parser.parse("$[?(null)]")
    assert {:ok, _parsed} = Parser.parse("$[?(true)]")
    # assert {:ok, _parsed} = Parser.parse("$[?@.key==42]")
    assert {:ok, _parsed} = Parser.parse("$[?(@.key)]")
    assert {:ok, _parsed} = Parser.parse("$.data.sum()")
    # assert {:ok, _parsed} = Parser.parse("$(key,more)")
    assert {:ok, _parsed} = Parser.parse("$..")
    assert {:ok, _parsed} = Parser.parse("$..*")
    assert {:ok, _parsed} = Parser.parse("$.key..")
    # assert {:ok, _parsed} = Parser.parse("$[(@.length-1)]")
    assert {:ok, _parsed} = Parser.parse("$[0,1]")
    assert {:ok, _parsed} = Parser.parse("$[0,0]")
    assert {:ok, _parsed} = Parser.parse("$['a','a']")
    # assert {:ok, _parsed} = Parser.parse("$[?(@.key<3),?(@.key>6)]")
    assert {:ok, _parsed} = Parser.parse("$['key','another']")
    assert {:ok, _parsed} = Parser.parse("$['missing','key']")
    assert {:ok, _parsed} = Parser.parse("$[:]['c','d']")
    assert {:ok, _parsed} = Parser.parse("$[0]['c','d']")
    assert {:ok, _parsed} = Parser.parse("$.*['c','d']")
    assert {:ok, _parsed} = Parser.parse("$..['c','d']")
    assert {:ok, _parsed} = Parser.parse("$[4,1]")
    # assert {:ok, _parsed} = Parser.parse("$.*[0,:5]")
    # assert {:ok, _parsed} = Parser.parse("$[1:3,4]")
    # assert {:ok, _parsed} = Parser.parse("$[ 0 , 1 ]")
    # assert {:ok, _parsed} = Parser.parse("$[*,1]")
  end
end
-module(steamroll_algebra_test).

-include_lib("eunit/include/eunit.hrl").

-define(sp, <<" ">>).
-define(nl, <<"\n">>).

-define(indent, 2).

paper_implementation_test() ->
    [
     ?_assertEqual(<<"if a == b then a << 2 else a + b\n">>, steamroll_algebra:from_the_paper(100, ?indent)),
     ?_assertEqual(<<"if a == b then a << 2 else a + b\n">>, steamroll_algebra:from_the_paper(32, ?indent)),
     ?_assertEqual(<<"if a == b\nthen a << 2\nelse a + b\n">>, steamroll_algebra:from_the_paper(15, ?indent)),
     ?_assertEqual(<<"if a == b\nthen\n  a << 2\nelse a + b\n">>, steamroll_algebra:from_the_paper(10, ?indent)),
     ?_assertEqual(<<"if\n  a == b\nthen\n  a << 2\nelse\n  a + b\n">>, steamroll_algebra:from_the_paper(8, ?indent)),
     ?_assertEqual(<<"if\n  a ==\n    b\nthen\n  a <<\n    2\nelse\n  a + b\n">>, steamroll_algebra:from_the_paper(7, ?indent)),
     ?_assertEqual(<<"if\n  a ==\n    b\nthen\n  a <<\n    2\nelse\n  a +\n    b\n">>, steamroll_algebra:from_the_paper(6, ?indent))
    ].

repeat_test_() ->
    [
     ?_assertEqual(<<>>, steamroll_algebra:repeat(?sp, 0)),
     ?_assertEqual(<<" ">>, steamroll_algebra:repeat(?sp, 1)),
     ?_assertEqual(<<"  ">>, steamroll_algebra:repeat(?sp, 2)),
     ?_assertEqual(<<"   ">>, steamroll_algebra:repeat(?sp, 3)),
     ?_assertEqual(<<"    ">>, steamroll_algebra:repeat(?sp, 4)),
     ?_assertEqual(<<"\n">>, steamroll_algebra:repeat(?nl, 1)),
     ?_assertEqual(<<"\n\n">>, steamroll_algebra:repeat(?nl, 2)),
     ?_assertEqual(<<"\n\n\n">>, steamroll_algebra:repeat(?nl, 3)),
     ?_assertEqual(<<"\n\n\n\n">>, steamroll_algebra:repeat(?nl, 4))
    ].

basic_brackets_test_() ->
    Tokens = steamroll_ast:tokens(<<"foo(Arg1, Arg2)">>),
    Expect0 = <<"foo(Arg1, Arg2)\n">>,
    Result0 = steamroll_algebra:format_tokens(Tokens, 100),
    Expect1 = <<"foo(\n    Arg1,\n    Arg2\n)\n">>,
    Result1 = steamroll_algebra:format_tokens(Tokens, 1),
    [
     ?_assertEqual(Expect0, Result0),
     ?_assertEqual(Expect1, Result1)
    ].

basic_function_test_() ->
    Tokens = steamroll_ast:tokens(<<"foo(Arg1, Arg2) -> ok.">>),
    Expect0 = <<"foo(Arg1, Arg2) -> ok.\n">>,
    Result0 = steamroll_algebra:format_tokens(Tokens, 100),
    Expect1 = <<"foo(Arg1, Arg2) ->\n    ok.\n">>,
    Result1 = steamroll_algebra:format_tokens(Tokens, 20),
    Expect2 = <<"foo(\n    Arg1,\n    Arg2\n) ->\n    ok.\n">>,
    Result2 = steamroll_algebra:format_tokens(Tokens, 1),
    [
     ?_assertEqual(Expect0, Result0),
     ?_assertEqual(Expect1, Result1),
     ?_assertEqual(Expect2, Result2)
    ].

function_test_() ->
    Tokens = steamroll_ast:tokens(<<"foo(Arg1, Arg2) -> Arg3 = Arg1 + Arg2, Arg3.">>),
    Expect0 = <<"foo(Arg1, Arg2) ->\n    Arg3 = Arg1 + Arg2,\n    Arg3.\n">>,
    Result0 = steamroll_algebra:format_tokens(Tokens, 30),
    Expect1 = <<"foo(Arg1, Arg2) ->\n    Arg3 =\n        Arg1 + Arg2,\n    Arg3.\n">>,
    Result1 = steamroll_algebra:format_tokens(Tokens, 20),
    [
     ?_assertEqual(Expect0, Result0),
     ?_assertEqual(Expect1, Result1)
    ].

function_clause_test_() ->
    Tokens = steamroll_ast:tokens(<<"foo(Arg1, Arg1) -> error; foo(Arg1, Arg2) -> ok.">>),
    Expect0 = <<"foo(Arg1, Arg1) -> error;\nfoo(Arg1, Arg2) -> ok.\n">>,
    Result0 = steamroll_algebra:format_tokens(Tokens, 100),
    Expect1 = <<"foo(Arg1, Arg1) ->\n    error;\nfoo(Arg1, Arg2) ->\n    ok.\n">>,
    Result1 = steamroll_algebra:format_tokens(Tokens, 20),
    Expect2 = <<"foo(\n    Arg1,\n    Arg1\n) ->\n    error;\nfoo(\n    Arg1,\n    Arg2\n) ->\n    ok.\n">>,
    Result2 = steamroll_algebra:format_tokens(Tokens, 1),
    [
     ?_assertEqual(Expect0, Result0),
     ?_assertEqual(Expect1, Result1),
     ?_assertEqual(Expect2, Result2)
    ].

basic_attribute_test_() ->
    Tokens = steamroll_ast:tokens(<<"-module(test).">>),
    Expect0 = <<"-module(test).\n">>,
    Result0 = steamroll_algebra:format_tokens(Tokens, 100),
    Expect1 = <<"-module(\n    test\n).\n">>,
    Result1 = steamroll_algebra:format_tokens(Tokens, 1),
    [
     ?_assertEqual(Expect0, Result0),
     ?_assertEqual(Expect1, Result1)
    ].

attribute_test_() ->
    Tokens = steamroll_ast:tokens(<<"-module(test).\n\n-export([start_link/0, init/1]).">>),
    Expect0 = <<"-module(test).\n\n-export([start_link/0, init/1]).\n">>,
    Result0 = steamroll_algebra:format_tokens(Tokens, 100),
    Expect1 = <<"-module(test).\n\n-export(\n    [start_link/0, init/1]\n).\n">>,
    Result1 = steamroll_algebra:format_tokens(Tokens, 30),
    Expect2 = <<"-module(test).\n\n-export(\n    [\n        start_link/0,\n        init/1\n    ]\n).\n">>,
    Result2 = steamroll_algebra:format_tokens(Tokens, 20),
    [
     ?_assertEqual(Expect0, Result0),
     ?_assertEqual(Expect1, Result1),
     ?_assertEqual(Expect2, Result2)
    ].

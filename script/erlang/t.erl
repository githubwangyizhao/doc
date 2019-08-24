-module(t).

-export([test/0]).
-export([sum0/2, sum1/1]).
-export([test1/0]).
-export([test5/0]).
-export([test7/0]).
-export([test8/0]).
-export([url_encode/1]).

-spec(url_encode(formdata()) -> string()).
url_encode(Data) -> url_encode(Data, "").
url_encode([], Acc) -> Acc;
url_encode([{Key, Value} | R], "") ->
	url_encode(R, edoc_lib:escape_uri(Key) ++ "=" ++ edoc_lib:escape_uri(Value));
url_encode([{Key, Value} | R], Acc) ->
	url_encode(R, Acc ++ "&" ++ edoc_lib:escape_uri(Key) ++ "=" ++ edoc_lib:escape_uri(Value)).

%% example usage:
%%httpc:request(post, {"http://localhost:3000/foo", [], "application/x-www-form-urlencoded", url_encode([{"username", "bob"}, {"password", "123456"}])},[],[]).

%%% ######################################
test8() ->
	StrA = term_to_string(0),
	io:format("StrA ~p~n", [StrA]),
	io:format("string_to_term(StrA) ~p~n", [string_to_term(StrA)]),
	is_integer(string_to_term(StrA)).

term_to_string([H|_] = Term) when is_integer(H)->
	case lists:all(fun erlang:is_integer/1, Term) of
		true -> lists:flatten(io_lib:format("~w", [Term]));
		false -> lists:flatten(io_lib:format("~p", [Term]))
	end;
term_to_string(Term) ->
	io:format("2222222 ~p~n", [Term]),
	lists:flatten(io_lib:format("~p", [Term])).
string_to_term(Str)->
	exec(to_list(Str) ++ ".").

exec(Str) ->
	{ok,Scanned,_} = erl_scan:string(to_list(Str)),
	{ok,Parsed} = erl_parse:parse_exprs( Scanned ),
	{value, Term,_} = erl_eval:exprs(Parsed,[]),
	Term.

to_list(Msg) when is_list(Msg) -> Msg;
to_list(Msg) when is_atom(Msg) -> atom_to_list(Msg);
to_list(Msg) when is_binary(Msg) -> binary_to_list(Msg);
to_list(Msg) when is_integer(Msg) -> integer_to_list(Msg);
to_list(Msg) when is_float(Msg) -> float_to_list(Msg, [{decimals, 2}, compact]);
to_list(Msg) when is_tuple(Msg) -> tuple_to_list(Msg);
to_list(_) -> throw(other_value).

%%% ######################################
test7() ->
	Params = [
		{a, {struct, [
			{key1, value1},
			{key2, value2}
		]}},
		{b, [
			{struct, []}
		]}],
	{ok, [A, B]} = get_values([a, b], Params),
	{A, B}.  %% {[{key1,value1},{key2,value2}], [{struct,[]}]}

get_values(List, Obj) ->
	get_values(List, Obj, []).
get_values([], _Obj, Acc) ->
	{ok, lists:reverse(Acc)};
get_values([{H, Def} | T], Obj, Acc) ->
	case lists:keytake(H, 1, Obj) of
		{value, {_, {struct, Sys}}, Obj1} ->
			get_values(T, Obj1, [Sys | Acc]);
		{value, {_, Sys}, Obj1} ->
			get_values(T, Obj1, [Sys | Acc]);
		false ->
			get_values(T, Obj, [Def | Acc])
	end;
get_values([H | T], Obj, Acc) ->
	case lists:keytake(H, 1, Obj) of
		{value, {_, {struct, Sys}}, Obj1} ->
			get_values(T, Obj1, [Sys | Acc]);
		{value, {_, Sys}, Obj1} ->
			get_values(T, Obj1, [Sys | Acc]);
		false ->
			{error, H}
	end.

%%% ######################################
test5() ->
	BaseList = [[1, 2, 3], [1, 2, 2], [1, 1, 3], [1, 1, 0], [1, 2, 0], [1, 2, 4]],
	io:format("~p", [test6(BaseList)]).

test6(List) ->
	lists:sort(
		fun(E1, E2) ->
			compareFunc(E1, E2)
		end, List).

compareFunc([], []) -> true;
compareFunc([H1 | T1], [H2 | T2]) ->
	case H1 of
		H2 -> compareFunc(T1, T2);
		_ -> H1 < H2
	end.

%%% ######################################
test() ->
	List = [{3, 1}, {4, 3}, {3, 2}, {4, 1}, {5, 0}, {4, 6}, {4, 5}],
	lists:sort(
		fun ({A, B}, {C, D}) ->
			case A of
				C -> B > D;
				_ -> A > C
			end
		end,
		List),
	length(List).

%%% ######################################
sum0(0, Total) -> Total;
sum0(N, Total) -> sum0(N-1, Total + N).

sum1(0) -> 0;
sum1(N) -> N + sum1(N-1).

%%% ######################################
test1() ->
	rand:seed(exs64),
	BaseList = [
		{{1, 1}, 0}, {{1, 2}, 0}, {{1, 3}, 0}, {{1, 4}, 0}, {{1, 5}, 0},
		{{2, 1}, 0}, {{2, 2}, 0}, {{2, 3}, 0}, {{2, 4}, 0}, {{2, 5}, 0},
		{{3, 1}, 0}, {{3, 2}, 0}, {{3, 3}, 0}, {{3, 4}, 0}, {{3, 5}, 0}
	],
	NewList = lists:map(
		fun({Pos, _}) ->
			{Pos, rand:uniform(5)}
		end, BaseList),
	FilterList = [{X, Y} || {{X, Y}, V} <- NewList, V =:= 1],
	io:format("\t NewList: ~p~n", [NewList]),
	io:format("\t FilterList: ~p~n", [FilterList]),
	io:format("result ~s~n", [test2(FilterList)]).

test2([]) -> false;
test2(List) ->
	lists:any(
		fun(E) ->
			test3(E, lists:delete(E, List), 1) >= 3
		end, List).

test3({X, Y}, List, Cnt) ->
	Cnt1 =
		case lists:member({X-1, Y}, List) of
			true -> test3({X-1, Y}, lists:delete({X-1, Y}, List), 1);
			false -> 0
		end,
	Cnt2 =
		case lists:member({X+1, Y}, List) of
			true -> test3({X+1, Y}, lists:delete({X+1, Y}, List), 1);
			false -> 0
		end,
	Cnt3 =
		case lists:member({X, Y+1}, List) of
			true -> test3({X, Y+1}, lists:delete({X, Y+1}, List), 1);
			false -> 0
		end,
	Cnt4 =
		case lists:member({X, Y-1}, List) of
			true -> test3({X, Y-1}, lists:delete({X, Y-1}, List), 1);
			false -> 0
		end,
	Cnt + Cnt1 + Cnt2 + Cnt3 + Cnt4.

%%% ######################################



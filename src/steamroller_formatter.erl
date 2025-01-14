-module(steamroller_formatter).

-export([format/2, format_code/1, test_format/1]).

-include_lib("kernel/include/logger.hrl").

-define(CRASHDUMP, "steamroller.crashdump").
-define(default_line_length, 100).

%% API

-spec format(binary(), list(any())) -> ok | {error, any()}.
format(File, Opts) ->
    Check = lists:member(check, Opts),
    LineLength =
        case proplists:get_value(line_length, Opts) of
            undefined -> ?default_line_length;
            Custom -> Custom
        end,
    case file:read_file(File) of
        {ok, Code} ->
            case format_code(Code, File, LineLength) of
                {ok, Code} -> ok;
                {ok, FormattedCode} ->
                    case Check of
                        true -> {error, <<"Check failed: code needs to be formatted.">>};
                        false -> file:write_file(File, FormattedCode)
                    end;
                {error, _} = Err -> Err
            end;
        {error, enoent} -> {error, <<"file does not exist">>};
        {error, eisdir} -> {error, <<"that's a directory">>};
        {error, _} = Err -> Err
    end.

-spec format_code(binary()) -> ok | {error, any()}.
format_code(Code) -> format_code(Code, <<"no_file">>, ?default_line_length).

% For testing.
% We give the file a proper name so that we compare the ASTs.
-spec test_format(binary()) -> ok | {error, any()}.
test_format(Code) -> format_code(Code, <<"test.erl">>, ?default_line_length).

%% Internal

-spec format_code(binary(), binary(), integer()) -> {ok, binary()} | {error, any()}.
format_code(Code, File, LineLength) ->
    {ok, R} = re:compile("\\.[he]rl$"),
    case re:run(File, R) of
        {match, _} ->
            % Check the AST after formatting for source files.
            case steamroller_ast:ast(Code, File) of
                {ok, OriginalAst} ->
                    Tokens = steamroller_ast:tokens(Code),
                    FormattedCode = steamroller_algebra:format_tokens(Tokens, LineLength),
                    case steamroller_ast:ast(FormattedCode, File) of
                        {ok, NewAst} ->
                            case steamroller_ast:eq(OriginalAst, NewAst) of
                                true -> {ok, FormattedCode};
                                false ->
                                    handle_formatting_error(
                                        {error, ast_mismatch},
                                        File,
                                        FormattedCode
                                    )
                            end;
                        {error, _} = Err -> handle_formatting_error(Err, File, FormattedCode)
                    end;
                {error, _} = Err -> Err
            end;
        nomatch ->
            % Don't check the AST for config files.
            Tokens = steamroller_ast:tokens(Code),
            {ok, steamroller_algebra:format_tokens(Tokens, LineLength)}
    end.

handle_formatting_error({error, _} = Err, File, FormattedCode) ->
    file:write_file(?CRASHDUMP, FormattedCode),
    {error, {formatter_broke_the_code, {file, File}, Err, {crashdump, ?CRASHDUMP}}}.

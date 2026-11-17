% Tower of Hanoi visualizer - SWI-Prolog backend
% Local run: swipl -q -s hanoi.pl
% Then open http://localhost:8000

:- use_module(library(http/thread_httpd)).
:- use_module(library(http/http_dispatch)).
:- use_module(library(http/http_parameters)).
:- use_module(library(http/http_json)).
:- use_module(library(http/http_files)).

:- http_handler(root(.), serve_index, []).
:- http_handler(root(moves), moves_handler, []).

main :-
    ( getenv('PORT', PortAtom) ->
        atom_number(PortAtom, Port)
    ;
        Port = 8000
    ),
    http_server(http_dispatch, [port(Port), ip('0.0.0.0')]),
    format('~nTower of Hanoi is running on port ~w~n', [Port]),
    thread_get_message(_).

% The file path is a fixed project file, so unsafe(true) is safe here.
% SWI-Prolog otherwise rejects the absolute path as a security precaution.
serve_index(Request) :-
    absolute_file_name('index.html', File, [access(read)]),
    http_reply_file(File, [mime_type(text/html), unsafe(true)], Request).

moves_handler(Request) :-
    http_parameters(Request, [n(N, [integer, between(1, 8)])]),
    hanoi_moves(N, a, c, b, Moves),
    length(Moves, Total),
    reply_json_dict(_{disks: N, total_moves: Total, moves: Moves}).

% hanoi_moves(+N, +Source, +Destination, +Auxiliary, -Moves)
hanoi_moves(1, Source, Destination, _Auxiliary,
            [_{disk: 1, from: Source, to: Destination}]) :- !.
hanoi_moves(N, Source, Destination, Auxiliary, Moves) :-
    N > 1,
    N1 is N - 1,
    hanoi_moves(N1, Source, Auxiliary, Destination, First),
    hanoi_moves(N1, Auxiliary, Destination, Source, Last),
    append(First,
           [_{disk: N, from: Source, to: Destination}|Last],
           Moves).

:- initialization(main, main).

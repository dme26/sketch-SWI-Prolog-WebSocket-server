:- use_module(library(http/thread_httpd)).
:- use_module(library(http/http_dispatch)).
:- use_module(library(http/websocket)).
:- use_module(library(http/json)).

start_server(Port) :-
    http_server(http_dispatch, [port(Port)]).

:- http_handler(root(ws), http_upgrade_to_websocket(accept_websocket, []), [spawn([])]).

:-dynamic open_websocket/1.

accept_websocket(WebSocket) :-
    format('New WebSocket connection established: ~w~n', [WebSocket]),
    assert(open_websocket(WebSocket)),
    wait_for_messages(WebSocket),
    retract(open_websocket(WebSocket)).
    
wait_for_messages(WebSocket) :-
    ws_receive(WebSocket, Message, [format(json)]), % blocking wait
    (   Message.opcode \= close
    ->  handle_message(Message),
        wait_for_messages(WebSocket)
    ;   format('WebSocket connection closed: ~w~n', [WebSocket])
    ).

handle_message(Message) :-
    format('Received message: ~w~n', [Message]).

send_test_data(WebSocket) :-
    dict_create(Data, _, [type-test,data-"Hello, WebSocket!"]),
    dict_create(Response_dict, _, [data-Data,format-json,opcode-text]),
    ws_send(WebSocket, Response_dict),
    format('Sent test data through WebSocket: ~w~n', [Data]).

% % Usage:
% start_server(1234).
% % Client connects to ws://localhost:1234/ws and accept_websocket will be invoked, which will assert open_websocket/1 to save the stream details.
% open_websocket(WS),send_test_data(WS).

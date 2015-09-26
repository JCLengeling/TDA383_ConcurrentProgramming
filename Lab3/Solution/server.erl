-module(server).
-export([loop/2, initial_state/1, list_contain/2, list_add/2]).
-include_lib("./defs.hrl").

% Produce initial state
initial_state(ServerName) ->
    #server_st{}.

%% ---------------------------------------------------------------------------

loop(St, Message) ->
    {not_implemented, St}.

list_contain([X|_],X) -> true;
list_contain([_|Y],X) -> list_contain(Y,X);
list_contain([],X) -> false.

list_add([],X) ->[X]; 
list_add([X|XS],YS) -> [X | list_add(XS,YS) ]. 

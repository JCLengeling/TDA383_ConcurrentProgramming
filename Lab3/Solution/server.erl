-module(server).
-export([loop/2, initial_state/1, create_state/2, list_contain/2, list_add/2]).
-include_lib("./defs.hrl").

% Produce initial state
initial_state(ServerName) ->
    #server_st{serverName = ServerName, list_userNames = []}.

create_state(ServerName, List_userNames) ->
    #server_st { serverName = ServerName, list_userNames = List_userNames }.

%% ---------------------------------------------------------------------------

loop(St, Message) ->		
	case  list_contain(St#server_st.list_userNames ,Message#dataTransmission.nickname) of
              true ->
                  Response = username_already_connected,
		  {Response, St};
              false ->
		  io:fwrite("The List Before: ~p~n", [St#server_st.list_userNames]),
                  NewList = list_add(St#server_st.list_userNames ,Message#dataTransmission.nickname),
		  Stnew =  create_state(St#server_st.serverName, NewList),
		  io:fwrite("The List After: ~p~n", [Stnew#server_st.list_userNames]),
                  Response =  ok,
		  {Response, Stnew}
        end.

list_contain([X|_],X) -> true;
list_contain([_|Y],X) -> list_contain(Y,X);
list_contain([],X) -> false.

list_add([],X) ->[X]; 
list_add([X|XS],YS) -> [X | list_add(XS,YS) ]. 

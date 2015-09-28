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
    receive
        stop -> true ;

        {print, From, Ref}->
            io:write("hi");

        {connnect, From, Ref, UserName} ->
            case  list_contain(St#server_st.list_userNames ,UserName) of
              true ->
                  From ! {result, Ref, username_already_connected };
                  %loop(St,Message)
              false ->
                  list_add(St#server_st.list_userNames ,UserName),
                  From ! {result, Ref, ok}
                  %loop(St,Message)
            end
    end.
    %{ok, St}.

list_contain([X|_],X) -> true;
list_contain([_|Y],X) -> list_contain(Y,X);
list_contain([],X) -> false.

list_add([],X) ->[X]; 
list_add([X|XS],YS) -> [X | list_add(XS,YS) ]. 

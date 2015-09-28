-module(client).
-export([loop/2, create_state/3, initial_state/2]).
-include_lib("./defs.hrl").

%% Produce initial state
initial_state(Nick, GUIName) ->
   #client_st { gui = GUIName, nickname = Nick, connected = false }.

create_state(Nick, GUIName, Connected) ->
   #client_st { gui = GUIName, nickname = Nick, connected = Connected }.

%% ---------------------------------------------------------------------------

%% loop handles each kind of request from GUI

%% Connect to server
loop(St, {connect, Server}) ->
    % {ok, St} ;
    %{{error, not_implemented, "Not implemented"}, St} ;

    %Ref = make_ref(),
    %list_to_atom(Server) ! {print, self(), Ref},
    %{ok, St};

    case  St#client_st.connected  of
    true ->
        {{error, user_already_connected, "You are already connected to a server."}, St};
    false->
        Ref = make_ref(),
        Result = genserver:request(list_to_atom(Server), #dataTransmission{nickname = St#client_st.nickname}) ,      
	io:fwrite("Client is receiving: ~p~n", [Result]), 
	case Result == ok of
             true ->
                     {ok, St};
             false ->
                     case Result == username_already_connected of
                            true ->
                               {{error, user_already_connected, "Username is already taken on server."}, St};
                            false ->
                               {{error, server_not_reached, "Server is not available right now."}, St}
                        end
                end
    end;


%% Disconnect from server
loop(St, disconnect) ->
    % {ok, St} ;
     {{error, not_implemented, "Not implemented"}, St} ;

% Join channel
loop(St, {join, Channel}) ->
    % {ok, St} ;
    {{error, not_implemented, "Not implemented"}, St} ;

%% Leave channel
loop(St, {leave, Channel}) ->
    % {ok, St} ;
    {{error, not_implemented, "Not implemented"}, St} ;

% Sending messages
loop(St, {msg_from_GUI, Channel, Msg}) ->
    % {ok, St} ;
    {{error, not_implemented, "Not implemented"}, St} ;

%% Get current nick
loop(St, whoami) ->
    {St#client_st.nickname, St} ;

%% Change nick
loop(St, {nick, Nick}) ->
 if	St#client_st.connected == true ->
		{{error, user_already_connected, "We are already connected, we can't change username when we are connected"}, St} ;
	true ->		{ok, Stnew = create_state(Nick, St#client_st.gui, St#client_st.connected)}
 end;

 

%% Incoming message
loop(St = #client_st { gui = GUIName }, {incoming_msg, Channel, Name, Msg}) ->
    gen_server:call(list_to_atom(GUIName), {msg_to_GUI, Channel, Name++"> "++Msg}),
    {ok, St}.

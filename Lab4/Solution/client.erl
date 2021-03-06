-module(client).
-export([loop/2, create_state/5, initial_state/2, list_contain/2, list_add/2,  list_isEmpty/1]).
-include_lib("./defs.hrl").

%% Produce initial state
initial_state(Nick, GUIName) ->
  #client_st{gui = GUIName, nickname = Nick, serverName = "", machineName = "", list_chatRoom = []}.

create_state(Nick, GUIName, ServerName, MachineName, List_chatRoom) ->
  #client_st{gui = GUIName, nickname = Nick, serverName = ServerName, machineName = MachineName, list_chatRoom = List_chatRoom}.

%% ---------------------------------------------------------------------------
%%/connect {shire, server@127.0.0.1}
%% loop handles each kind of request from GUI+

%% Connect to Remote server
loop(St, {connect, {Server,Machine}}) ->
  %io:fwrite("~nChannel: ~p~n", ["Here"]),
  case St#client_st.serverName == "" of
    false ->
      {{error, user_already_connected, "You are already connected to a server."}, St};
    true ->
      case catch(  genserver:request({list_to_atom(Server), list_to_atom(Machine)}, #data_trsmn{type = 0, data = [St#client_st.nickname]})) of
        ok ->
          Stnew = create_state(St#client_st.nickname, St#client_st.gui, Server, Machine, St#client_st.list_chatRoom),
          {ok, Stnew};
        username_already_connected ->
          {{error, user_already_connected, "Username is already taken on server."}, St};
        {'EXIT', Reason} ->
          {{error, server_not_reached, "Server is not available right now."}, St}
      end
  end;



%% Connect to server
loop(St, {connect, Server}) -> 
  case St#client_st.serverName == "" of
    false ->
      {{error, user_already_connected, "You are already connected to a server."}, St};
    true ->
      case catch(  genserver:request(list_to_atom(Server), #data_trsmn{type = 0, data = [St#client_st.nickname]})) of
        ok ->
          Stnew = create_state(St#client_st.nickname, St#client_st.gui, Server, "", St#client_st.list_chatRoom),
          {ok, Stnew};
        username_already_connected ->
          {{error, user_already_connected, "Username is already taken on server."}, St};
        {'EXIT', Reason} ->
          {{error, server_not_reached, "Server is not available right now."}, St}
      end
  end;



%% Disconnect from server
loop(St, disconnect) ->
  case St#client_st.serverName == "" of
    true ->
      {{error, user_not_connected, "You are not connected to a server."}, St};
    false ->
      case list_isEmpty(St#client_st.list_chatRoom) of
        false ->
          {{error, leave_channels_first, "You cannot leave a server if you are still in a channel"}, St};
        true ->
		case St#client_st.machineName == "" of
			true ->
				Result = genserver:request(list_to_atom(St#client_st.serverName), #data_trsmn{type = 2, data = [St#client_st.nickname]}),
          			case Result == ok of
            				true ->
              					Stnew = create_state(St#client_st.nickname, St#client_st.gui, "", "", St#client_st.list_chatRoom),
              					{ok, Stnew};
            				false ->
              					{{error, server_not_reached, "Cannot reach the server"}, St}
          			end;
			false ->
				Result = genserver:request({list_to_atom(St#client_st.serverName), list_to_atom(St#client_st.machineName)  }, #data_trsmn{type = 2, data = [St#client_st.nickname]}),
          			case Result == ok of
            				true ->
              					Stnew = create_state(St#client_st.nickname, St#client_st.gui, "", "", St#client_st.list_chatRoom),
              					{ok, Stnew};
            				false ->
              				{{error, server_not_reached, "Cannot reach the server"}, St}
          			end
				
		end
      end
  end;


% Join channel
loop(St, {join, Channel}) ->
  case list_to_atom(St#client_st.serverName) == list_to_atom("") of
    true ->
      {{error, user_not_connected, "You are not connected to a server."}, St};
    false ->
      case list_contain(St#client_st.list_chatRoom, Channel) of
        true ->
          {{error, user_already_joined, "You are already on this channel."}, St};
        false ->
	  case St#client_st.machineName == "" of
		true ->
          		Result = genserver:request(list_to_atom(St#client_st.serverName), #data_trsmn{type = 1, data = [Channel]}),
          		case Result of
            			ok ->
           	   			Result2 = genserver:request(list_to_atom(Channel), #data_trsmn{type = 0, data = [St#client_st.nickname, self()]}),
              				case Result2 of
                				ok ->
                  					NewList = list_add(St#client_st.list_chatRoom, Channel),
                  					Stnew = create_state(St#client_st.nickname, St#client_st.gui, St#client_st.serverName, St#client_st.machineName,  NewList),
                  					{ok, Stnew}
					end
          		end;
		false ->
			Result = genserver:request({list_to_atom(St#client_st.serverName), list_to_atom(St#client_st.machineName) }, #data_trsmn{type = 1, data = [Channel]}),
          		case Result of
            			ok ->
           	   			Result2 = genserver:request({list_to_atom(Channel),  list_to_atom(St#client_st.machineName) }, #data_trsmn{type = 0, data = [St#client_st.nickname, self()]}),
              				case Result2 of
                				ok ->
                  					NewList = list_add(St#client_st.list_chatRoom, Channel),
                  					Stnew = create_state(St#client_st.nickname, St#client_st.gui, St#client_st.serverName, St#client_st.machineName,  NewList),
                  					{ok, Stnew}
					end
          		end
           	end	
      end
  end;


%% Leave channel
loop(St, {leave, Channel}) ->
  case list_contain(St#client_st.list_chatRoom, Channel) of
    false ->
      {{error, user_not_joined, "You cannot leave a channel you have not joined"}, St};
    true ->
	case  St#client_st.machineName == "" of
		true ->
			Result = genserver:request(list_to_atom(Channel), #data_trsmn{type = 2, data = [St#client_st.nickname, self()]}),
      			case Result of
        			ok ->
          				NewList = lists:delete(Channel, St#client_st.list_chatRoom),
         				Stnew = create_state(St#client_st.nickname, St#client_st.gui, St#client_st.serverName, St#client_st.machineName,  NewList),
          				{ok, Stnew}
      			end;
		false -> 
			Result = genserver:request({list_to_atom(Channel),  list_to_atom(St#client_st.machineName) }, #data_trsmn{type = 2, data = [St#client_st.nickname, self()]}),
      			case Result of
        			ok ->
          				NewList = lists:delete(Channel, St#client_st.list_chatRoom),
         				Stnew = create_state(St#client_st.nickname, St#client_st.gui, St#client_st.serverName, St#client_st.machineName,  NewList),
          				{ok, Stnew}
      			end
	end
  end;

% Sending messages
loop(St, {msg_from_GUI, Channel, Msg}) ->
  case list_contain(St#client_st.list_chatRoom, Channel) of
    false ->
      {{error, user_not_joined, "You are not member of this channel"}, St};
    true ->
	case  St#client_st.machineName == "" of
		true ->
			Result = genserver:request(list_to_atom(Channel), #data_trsmn{type = 3, data = [Msg, Channel, St#client_st.nickname]}),
		 	{ok, St};
		false ->
			Result = genserver:request({list_to_atom(Channel),  list_to_atom(St#client_st.machineName)}, #data_trsmn{type = 3, data = [Msg, Channel, St#client_st.nickname]}),
		 	{ok, St}
	end
  end;

%

%% Get current nick
loop(St, whoami) ->
  {St#client_st.nickname, St};

%% Change nick
loop(St, {nick, Nick}) ->
  case St#client_st.serverName == "" of
    false ->
      {{error, user_already_connected, "We are already connected, we can't change username when we are connected"}, St};
    true ->
      {ok, create_state(Nick, St#client_st.gui, St#client_st.serverName,St#client_st.machineName, St#client_st.list_chatRoom)}
  end;


%% Incoming message
loop(St = #client_st{gui = GUIName}, {incoming_msg, Channel, Name, Msg}) ->
  gen_server:call(list_to_atom(GUIName), {msg_to_GUI, Channel, Name ++ "> " ++ Msg}),
  {ok, St}.


list_isEmpty([]) -> true;
list_isEmpty([_ | _]) -> false.


list_contain([X | _], X) -> true;
list_contain([_ | Y], X) -> list_contain(Y, X);
list_contain([], _) -> false.

list_add([], X) -> [X];
list_add([X | XS], YS) -> [X | list_add(XS, YS)].



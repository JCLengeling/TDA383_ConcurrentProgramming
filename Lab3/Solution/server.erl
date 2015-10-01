-module(server).
-export([loop/2, initial_state/1, create_state/3, list_contain/2, list_add/2, channelLoop/2, initial_state_channel/1, create_state_channel/2, list_remove/2, sendAll/4 ]).
-include_lib("./defs.hrl").

% Produce initial state
initial_state(ServerName) ->
    #server_st{serverName = ServerName, list_userNames = [], list_chatRoom = []}.

create_state(ServerName, List_userNames, List_chatRoom) ->
    #server_st { serverName = ServerName, list_userNames = List_userNames, list_chatRoom = List_chatRoom }.



initial_state_channel(ChannelName) ->
    #channel_st{list_userNames = [], channelName = ChannelName}.

create_state_channel(List_userNames, ChannelName) ->
    #channel_st {list_userNames = List_userNames,channelName =  ChannelName }.

%% ---------------------------------------------------------------------------

loop(St, Message) ->		
io:fwrite("The type of the message is: ~p~n", [Message#data_trsmn.type]),
io:fwrite("The data we send is: ~p~n", [Message#data_trsmn.data]),
case Message#data_trsmn.type of
	0 ->
		[Nickname] = Message#data_trsmn.data,
		case  list_contain(St#server_st.list_userNames ,Nickname) of
	              true ->
 	                 Response = username_already_connected,
			  {Response, St};
        	      false ->
			  NewList = list_add(St#server_st.list_userNames ,Nickname),
			  Stnew =  create_state(St#server_st.serverName, NewList, St#server_st.list_chatRoom ),
        	          Response =  ok,
			  {Response, Stnew}
        	end;
	1 -> 
		[Channel] = Message#data_trsmn.data,
		case list_contain(St#server_st.list_chatRoom ,Channel) of
			false ->
				State = initial_state_channel(Channel),
				genserver:start(list_to_atom(Channel), State, fun server:channelLoop/2),
				NewList = list_add(St#server_st.list_chatRoom ,Channel),
			  	Stnew =  create_state(St#server_st.serverName, St#server_st.list_userNames ,NewList),
				Response =  ok,				
				{Response, Stnew};
			true ->
				Response =  ok,
				{Response, St}
		end;
	2 ->
		[Nickname] = Message#data_trsmn.data,
		NewList = list_remove(St#server_st.list_userNames ,Nickname),
		Stnew =  create_state(St#server_st.serverName, NewList, St#server_st.list_chatRoom ),
		Response =  ok,
		{Response, Stnew}
end.		

%% CHANNEL !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
channelLoop(St, Message) ->
	case Message#data_trsmn.type of
		0 -> % connect user to channel
			[Nick, Pid] = Message#data_trsmn.data,
			Newlist = list_add(St#channel_st.list_userNames, {Nick, Pid}),
			Stnew = create_state_channel(Newlist, St#channel_st.channelName),
			Response =  ok,
			{Response, Stnew};
		2 -> 
			[Nick, Pid] = Message#data_trsmn.data,
			Newlist = list_remove(St#channel_st.list_userNames, {Nick, Pid}),
			Stnew = create_state_channel(Newlist, St#channel_st.channelName),
			Response =  ok,
			{Response, Stnew};
		3 -> 
			[Msg, Channel, Nick] = Message#data_trsmn.data,
			sendAll(St#channel_st.list_userNames, Msg,Channel, Nick),
			%foreach(fun(H) ->
				%{Nick, Pid} = H,
				%genserver:request(list_to_atom(Pid), #broadcast{ incoming_msg = incoming_msg, channel = Channel, name = Nick, msg = Msg})
			 	%end,
				%St#channel_st.list_userNames ),
			Response =  ok,
			{Response, St}			
	end.


sendAll([X|XS], Msg,Channel, Nick) -> 
	{Nickname, Pid} = X,
	io:fwrite("We send to: ~p~n", [Pid]),
	io:fwrite("The data we send is: ~p~n", [{incoming_msg, Channel, Nick, Msg}]),
	genserver:requestAsync(Pid, {incoming_msg, Channel, Nick, Msg}),
	%genserver:request(Pid,{incoming_msg, Channel, Nick, Msg}),
	sendAll(XS, Msg,Channel,Nick);
sendAll([], Msg,Channel, Nick) -> true.


list_remove([],X) ->[]; 
list_remove([X],X) ->[];
list_remove([X,Y|XS],X) -> [Y|list_remove(XS, X)].


list_contain([X|_],X) -> true;
list_contain([_|Y],X) -> list_contain(Y,X);
list_contain([],X) -> false.

list_add([],X) ->[X]; 
list_add([X|XS],YS) -> [X | list_add(XS,YS) ]. 


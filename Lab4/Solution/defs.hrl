% This record defines the structure of the client process.
% Add whatever other fields you need.
% It contains the following fields:

%   gui: the name (or Pid) of the GUI process.
-record(client_st, {gui,nickname, serverName, machineName, list_chatRoom}).

% This record defines the structure of the server process.
% Add whatever other fields you need.
-record(server_st, {list_userNames, list_chatRoom, serverName }).

-record(channel_st, {list_userNames, channelName }).
%-record(broadcast, {incoming_msg, channel, name, msg}).

-record(data_trsmn,{type,data}).

-record(chat_room,{data}).

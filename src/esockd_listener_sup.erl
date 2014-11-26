%%-----------------------------------------------------------------------------
%% Copyright (c) 2014, Feng Lee <feng.lee@slimchat.io>
%% 
%% Permission is hereby granted, free of charge, to any person obtaining a copy
%% of this software and associated documentation files (the "Software"), to deal
%% in the Software without restriction, including without limitation the rights
%% to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
%% copies of the Software, and to permit persons to whom the Software is
%% furnished to do so, subject to the following conditions:
%% 
%% The above copyright notice and this permission notice shall be included in all
%% copies or substantial portions of the Software.
%% 
%% THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
%% IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
%% FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
%% AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
%% LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
%% OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
%% SOFTWARE.
%%------------------------------------------------------------------------------

-module(esockd_listener_sup).

-behaviour(supervisor).

-export([start_link/3,
		 start_link/4]).

-export([init/1]).

start_link(Port, SocketOpts, Callback) ->
    start_link(Port, SocketOpts, Callback, 1).

start_link(Port, SocketOpts, Callback, AcceptorNum) ->
    {ok, Sup} = supervisor:start_link(?MODULE, []),
	{ok, ClientSup} = supervisor:start_child(Sup, 
		{client_sup, 
			{esockd_client_sup, start_link, [Callback]}, 
				transient, infinity, supervisor, [esockd_client_sup]}),
	{ok, AcceptorSup} = supervisor:start_child(Sup, 
		{acceptor_sup, 
			{esockd_acceptor_sup, start_link, [ClientSup]},
				transient, infinity, supervisor, [esockd_acceptor_sup]}),
	{ok, _Listener} = supervisor:start_child(Sup, 
		{listener, 
			{esockd_listener, start_link, [Port, SocketOpts, AcceptorSup, AcceptorNum]},
				transient, 16#ffffffff, worker, [esockd_listener]}),
	{ok, Sup}.

init([]) ->
    {ok, {{one_for_all, 10, 10}, []}}.

%start_link(IPAddress, Port, SocketOpts, OnStartup, OnShutdown,
%           AcceptCallback, ConcurrentAcceptorCount, Label) ->
%    supervisor:start_link(
%      ?MODULE, {IPAddress, Port, SocketOpts, OnStartup, OnShutdown,
%                AcceptCallback, ConcurrentAcceptorCount, Label}).

%init({IPAddress, Port, SocketOpts, OnStartup, OnShutdown,
%      AcceptCallback, ConcurrentAcceptorCount, Label}) ->
%    {ok, {{one_for_all, 10, 10}, []}.

-module(santa).
-export([start/0]).

worker(Secretary, Message) ->
    receive after random:uniform(1000) -> ok end,  % random delay
    Secretary ! self(),			% send my PID to the secretary
    Gate_Keeper = receive X -> X end,	% await permission to enter
    io:put_chars(Message),		% do my action
    Gate_Keeper ! {leave,self()},	% tell the gate-keeper I'm done
    worker(Secretary, Message).		% do it all again

secretary(Santa, Species, Count) ->
    secretary_loop(Count, [], {Santa,Species,Count}).

secretary_loop(0, Group, {Santa,Species,Count}) ->
    Santa ! {Species,Group},
    secretary(Santa, Species, Count);
secretary_loop(N, Group, State) ->
    receive PID ->
        secretary_loop(N-1, [PID|Group], State)
    end.

santa() ->
    {Species,Group} =
	receive				% first pick up a reindeer group
	    {reindeer,G} -> {reindeer,G}% if there is one, otherwise
	after 0 ->
	        receive			% wait for reindeer or elves,
	            {reindeer,G} -> {reindeer,G}
	          ; {elves,G}    -> {elves,G}
	        end			% whichever turns up first.
	end,	        
    case Species
      of reindeer -> io:put_chars("Ho, ho, ho!  Let's deliver toys!\n")
       ; elves    -> io:put_chars("Ho, ho, ho!  Let's meet in the study!\n")
    end,
    [PID ! self() || PID <- Group],	% tell them all to enter
    [receive {leave,PID} -> ok end	% wait for each of them to leave
	|| PID <- Group],
    santa().

spawn_worker(Secretary, Before, I, After) ->
    Message = Before ++ integer_to_list(I) ++ After,
    spawn(fun () -> worker(Secretary, Message) end).

start() ->
    Santa = spawn(fun () -> santa() end),
    Robin = spawn(fun () -> secretary(Santa, reindeer, 9) end),
    Edna  = spawn(fun () -> secretary(Santa, elves,    3) end),
    [spawn_worker(Robin, "Reindeer ", I, " delivering toys.\n")
     || I <- lists:seq(1, 9)],
    [spawn_worker(Edna,  "Elf ",      I, " meeting in the study.\n")
     || I <- lists:seq(1, 10)].


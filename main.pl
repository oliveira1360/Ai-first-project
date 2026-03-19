% :-consult('xpto.pl')

printList([]) :- nl.
		
printList([H | T]) :-
	write(H), write(' '),
	printList(T).	

printTable([]).
		
printTable([Row | Tail]) :-
	printList(Row), 
	printTable(Tail).


replace(Idx, List, Value, NewList) :-
	replaceAux(0, Idx, List, Value, NewList).


replaceAux(Idx, Idx, [H | Tail], Value, [Value | Tail]).

replaceAux(Idx1, Idx, [H | Tail], Value, [H | NewTail]) :-
	Idx1 =\= Idx, % Idx1 != Idx 
	Idx2 is Idx1 + 1,
	replaceAux(Idx2, Idx, Tail, Value, NewTail).


replaceTableGame([], Value, New).

replaceTableGame([Row | Tail], Value, NewTable) :-
    nth0(Idx, List, Value, NewTable),
    nth0(Idx, NewList, . , NewTable),
    replaceTable(Tail, Value, N).


replaceTable(Row, Col, Table, Value, NewTable) :-
	nth0(Row, Table, Line),
	replace(Col, Line, Value, NewLine),
	replace(Row, Table, NewLine, NewTable).	


first(C, [C|_]).

second(X, [_, X|_]).

% Predicate third(E, L):
% Succeeds if E is the third element of list L.
third(X, [_, _, X|_]).



% [[.,.,.],[.,.,.],[.,.,.]]
% play(x,[[.,.,.],[.,.,.],[.,.,.]],Newboard).
play(RoundNumber, Board, NewBoard, PlayerXX, PlayerXY,) :-
    read(X/Y),
    Xpto is RoundNumber mod 2,
    (Xpto = 0 -> Player = x; Player = o),
    replaceTable(X,Y,Board, Player, NewBoard),
    printTable(NewBoard),
    NewRoundNumber is RoundNumber + 1,
    play(NewRoundNumber, NewBoard, B).








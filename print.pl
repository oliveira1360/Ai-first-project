printList([]) :- nl.
		
printList([H | T]) :-
	write(H), write(' '),
	printList(T).	

printTable([]).
		
printTable([Row | Tail]) :-
	printList(Row), 
	printTable(Tail).
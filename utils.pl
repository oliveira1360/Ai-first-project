indexOf(Board, Element, Row, Col) :-
    nth0(Row, Board, RowList),
    
    nth0(Col, RowList, Element).


isValidPlay(X,Y,Player, Board,OldX,OldY) :-
    indexOf(Board, Player, OldX, OldY),
    indexOf(Board,'.',X,Y),
    DiffX is OldX - X,
    DiffY is OldY - Y,
	member(DiffX, [-1, 0, 1]),
    member(DiffY, [-1, 0, 1]),
    \+ (OldX =:= X , OldY =:= Y).
    

% isBlocked(0,0,[[x,#,.],[#,#,.],[.,.,o]]).
isBlocked(Player, Board) :-
    indexOf(Board, Player, PosX, PosY),
    \+ (
        member(DX, [-1, 0, 1]),
        member(DY, [-1, 0, 1]),
        NX is PosX + DX,
        NY is PosY + DY,
        isValidPlay(NX, NY, Player, Board, PosX, PosY)
    ).


putSharp(Board, X, Y, NewBoard) :-
    indexOf(Board, '.', X, Y),
    replaceTable(X, Y, Board, '#', NewBoard).

setupSharp(Board, NewBoard) :-
    format('~nEscolha onde colocar um "#" (Row/Col): '),
    read(X/Y),
    (
    	(putSharp(Board, X, Y, NewBoard)) -> 
        (
            write('Obstaculo colocado!'), nl,
            printTable(NewBoard)
        )
        ;
        (
            write('Local ocupado ou invalido! Tente de novo.'), nl,
            setupSharp(Board, NewBoard)
        )
    ).


first(C, [C|_]).

second(X, [_, X|_]).

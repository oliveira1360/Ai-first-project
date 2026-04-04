% The alpha-beta algorithm

alphabeta(Pos, _, _, Pos, Val, Depth, Depth) :- 
    !, 
    staticval(Pos, Val).

alphabeta(Pos, Alpha, Beta, GoodPos, Val, CurrentDepth, FinalDepth) :-
    CurrentDepth < FinalDepth,
    moves(Pos, PosList), 
    !,
    NextDepth is CurrentDepth + 1,
    boundedbest(PosList, Alpha, Beta, GoodPos, Val, NextDepth, FinalDepth).

alphabeta(Pos, _, _, Pos, Val, _, _) :-
    staticval(Pos, Val).

boundedbest([Pos | PosList], Alpha, Beta, GoodPos, GoodVal, Depth, Max) :-
    alphabeta(Pos, Alpha, Beta, _, Val, Depth, Max),
    goodenough(PosList, Alpha, Beta, Pos, Val, GoodPos, GoodVal, Depth, Max).

goodenough([], _, _, Pos, Val, Pos, Val, _, _) :- !.

goodenough(_, Alpha, Beta, Pos, Val, Pos, Val, _, _) :-
    min_to_move(Pos), Val > Beta, !.
goodenough(_, Alpha, Beta, Pos, Val, Pos, Val, _, _) :-
    max_to_move(Pos), Val < Alpha, !.

goodenough(PosList, Alpha, Beta, Pos, Val, GoodPos, GoodVal, Depth, Max) :-
    newbounds(Alpha, Beta, Pos, Val, NewAlpha, NewBeta),
    boundedbest(PosList, NewAlpha, NewBeta, Pos1, Val1, Depth, Max),
    betterof(Pos, Val, Pos1, Val1, GoodPos, GoodVal).

newbounds( Alpha, Beta, Pos, Val, Val, Beta) :-
	min_to_move( Pos), Val > Alpha, !.         % Maximizer increased lower bound

newbounds( Alpha, Beta, Pos, Val, Alpha, Val) :-
	max_to_move( Pos), Val < Beta, !.          % Minimizer decreased upper bound
	
	
	
newbounds( Alpha, Beta, _, _, Alpha, Beta). % Otherwise bounds unchanged


betterof( Pos, Val, Pos1, Val1, Pos, Val) :-   % Pos better than Pos1
	min_to_move( Pos), Val > Val1, !
	; % Or
	max_to_move( Pos), Val < Val1, !.


betterof( _, _, Pos1, Val1, Pos1, Val1). % Otherwise Pos1 better


auxMoves([Player, Board], FinalBoard) :-
    indexOf(Board, Player, PosX, PosY),
    member(DX, [-1, 0, 1]),
    member(DY, [-1, 0, 1]),
   (DX \= 0 ; DY \= 0),         
    NX is PosX + DX,
    NY is PosY + DY,
        
    isValidPlay(NX, NY, Player, Board, PosX, PosY),
        
    replaceTable(PosX, PosY, Board, '.', TempBoard1),
    replaceTable(NX, NY, TempBoard1, Player, TempBoard2),
        

    indexOf(TempBoard2, '.', RemoveX, RemoveY),
    replaceTable(RemoveX, RemoveY, TempBoard2, '#', FinalBoard).

moves([Player, Board], PossibleMoveList) :-
    (Player == x -> NextPlayer = o ; NextPlayer = x),
    findall([NextPlayer, NewBoard], auxMoves([Player, Board], NewBoard), PossibleMoveList),
    PossibleMoveList \= [].


min_to_move([x | _Tail]).
max_to_move([o | _Tail]).


staticval([o, Board], -1000) :- mobilidade(o, Board, 0), !. % 'o' não tem movimentos (Perdeu)
staticval([x, Board], 1000)  :- mobilidade(x, Board, 0), !. % 'x' não tem movimentos (Ganhou)

staticval([_, Board], Val) :-
    mobilidade(o, Board, MovMax),
    mobilidade(x, Board, MovMin),
    Val is MovMax - MovMin. % Computador (o) quer maximizar as suas opções e minimizar as do jogador (x)

% Em vez de gerar tabuleiros com auxMoves, apenas conta as casas à volta que são válidas! (Máximo de 8 verificações em vez de dezenas)
mobilidade(Player, Board, Count) :-
    indexOf(Board, Player, PosX, PosY),
    findall(1, (
        member(DX, [-1, 0, 1]),
        member(DY, [-1, 0, 1]),
        (DX \= 0 ; DY \= 0),
        NX is PosX + DX,
        NY is PosY + DY,
        isValidPlay(NX, NY, Player, Board, PosX, PosY)
    ), ValidSpots),
    length(ValidSpots, Count).


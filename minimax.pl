   % minimax( Pos, BestSucc, Val):
   %   Pos is a position, Val is its minimax value;
   %   best move from Pos leads to position BestSucc
minimax( Pos, BestSucc, Val) :-
      moves( Pos, PosList), !,      % Legal moves in Pos produce PosList
      best( PosList, BestSucc, Val)
      ; % Or
      staticval( Pos, Val).         % Pos has no successors: evaluate statically
      
      
best( [Pos], Pos, Val) :-
      minimax( Pos, _, Val), !.


best( [Pos1 | PosList], BestPos, BestVal) :-
      minimax( Pos1, _, Val1),
      best( PosList, Pos2, Val2),
      betterof( Pos1, Val1, Pos2, Val2, BestPos, BestVal).


betterof( Pos0, Val0, Pos1, Val1, Pos0, Val0) :- % Pos0 better than Pos1
      min_to_move( Pos0),     % MIN to move in Pos0
      Val0 > Val1, !          % MAX prefers the greater value
      ; % Or 
      max_to_move( Pos0),     % MAX to move in Pos0
      Val0 < Val1, !.         % MIN prefers the lesser value


betterof( Pos0, Val0, Pos1, Val1, Pos1, Val1). % Otherwise Pos1 better than Pos0


% auxMoves(EstadoAtual, NovoTabuleiroGerado)
auxMoves([Player, Board], FinalBoard) :-
    % --- 1. FASE DE MOVIMENTO ---
    indexOf(Board, Player, PosX, PosY),
    
    % Gera offsets para as 8 direções adjacentes
    member(DX, [-1, 0, 1]),
    member(DY, [-1, 0, 1]),
    (DX \= 0 ; DY \= 0), % Garante que a peça sai do sítio (não pode ficar parada)
    
    NX is PosX + DX,
    NY is PosY + DY,
    
    % Verifica se a casa de destino é válida (está dentro do tabuleiro e livre)
    isValidPlay(NX, NY, Player, Board, PosX, PosY),
    
    % Executa o movimento: limpa a casa antiga e coloca o jogador na nova
    replaceTable(PosX, PosY, Board, '.', TempBoard1),
    replaceTable(NX, NY, TempBoard1, Player, TempBoard2),
    
    % --- 2. FASE DE REMOÇÃO (ISOLAMENTO) ---
    % Encontra as coordenadas (RemoveX, RemoveY) de UMA casa que esteja vazia ('.')
    % O Prolog, por backtracking, vai testar TODAS as casas vazias disponíveis neste TempBoard2!
    indexOf(TempBoard2, '.', RemoveX, RemoveY),
    
    % Substitui essa casa vazia por '#' (bloqueada)
    replaceTable(RemoveX, RemoveY, TempBoard2, '#', FinalBoard).

moves([Player, Board], PossibleMoveList) :-
    (Player == x -> NextPlayer = o ; NextPlayer = x),
    findall([NextPlayer, NewBoard], auxMoves([Player, Board], NewBoard), PossibleMoveList),
    PossibleMoveList \= [].


min_to_move([x | _Tail]).
max_to_move([o | _Tail]).


staticval([o, Board], -1000) :-
    conta_movimentos_validos(o, Board, 0), !.

staticval([x, Board], 1000) :-
    conta_movimentos_validos(x, Board, 0), !.

staticval([_, Board], Val) :-
    conta_movimentos_validos(o, Board, MovimentosMAX),
    conta_movimentos_validos(x, Board, MovimentosMIN),
    Val is MovimentosMAX - MovimentosMIN.

conta_movimentos_validos(Jogador, Tabuleiro, NumeroDeMovimentos) :-
    findall([NextPlayer, NewBoard], auxMoves([Jogador, Tabuleiro], NewBoard), PossibleMoveList),
    (Jogador == x -> NextPlayer = o ; NextPlayer = x),
    length(PossibleMoveList, NumeroDeMovimentos).

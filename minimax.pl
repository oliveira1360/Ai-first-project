% =============================================================================
% minimax.pl - Algoritmo Minimax clássico (sem limite de profundidade)
%
% Implementa o algoritmo Minimax para o jogo ISOLA. Explora a árvore de jogo
% até ao fim (estados terminais), sem limite de profundidade.
%
% Adequado apenas para tabuleiros pequenos (ex: 3x3), pois o fator de
% ramificação elevado torna-o impraticável em tabuleiros maiores (ex: 6x6).
%
% Convenção de papéis:
%   'x' → Minimizador (MIN) — o humano
%   'o' → Maximizador (MAX) — o computador
%
% Estado representado como: [Player, Board]
%   Player - jogador que vai jogar neste estado
%   Board  - tabuleiro atual (lista de listas)
% =============================================================================


% minimax( Pos, BestSucc, Val):
%   Pos is a position, Val is its minimax value;
%   best move from Pos leads to position BestSucc

% -----------------------------------------------------------------------------
% minimax(+Pos, -BestSucc, -Val)
%
% Predicado principal do Minimax. Dado um estado Pos, calcula o melhor
% estado sucessor BestSucc e o seu valor minimax Val.
%
% Funcionamento:
%   - Se existirem estados sucessores (moves/2 tem sucesso), delega em best/3.
%   - Se não existirem sucessores (estado terminal), avalia estaticamente
%     com staticval/2 (corte com ! evita tentar o ramo staticval desnecessariamente).
% -----------------------------------------------------------------------------
minimax( Pos, BestSucc, Val) :-
      moves( Pos, PosList), !,      % Legal moves in Pos produce PosList
      best( PosList, BestSucc, Val)
      ; % Or
      staticval( Pos, Val).         % Pos has no successors: evaluate statically


% -----------------------------------------------------------------------------
% best(+[Pos], -Pos, -Val)
%
% Caso base: lista com um único candidato.
% Avalia esse candidato com minimax e retorna-o como o melhor.
% O corte (!) evita que o caso recursivo seja tentado com uma lista unitária.
% -----------------------------------------------------------------------------
best( [Pos], Pos, Val) :-
    minimax( Pos, _, Val), !.


% -----------------------------------------------------------------------------
% best(+[Pos1|PosList], -BestPos, -BestVal)
%
% Caso recursivo: avalia o primeiro candidato (Pos1), obtém o melhor do
% resto (Pos2), e compara os dois via betterof/6 para devolver o melhor.
% -----------------------------------------------------------------------------
best( [Pos1 | PosList], BestPos, BestVal) :-
    minimax( Pos1, _, Val1),                            % Avalia o primeiro candidato
    best( PosList, Pos2, Val2),                         % Melhor do resto da lista
    betterof( Pos1, Val1, Pos2, Val2, BestPos, BestVal). % Compara os dois


% -----------------------------------------------------------------------------
% betterof(+Pos0, +Val0, +Pos1, +Val1, -BestPos, -BestVal)
%
% Compara dois estados e devolve o melhor, de acordo com o papel do jogador:
%   - Se MIN joga em Pos0 e Val0 > Val1 → Pos0 é melhor (MAX prefere valores maiores)
%   - Se MAX joga em Pos0 e Val0 < Val1 → Pos0 é melhor (MIN prefere valores menores)
%
% Caso contrário (segundo caso), Pos1 é considerado melhor por defeito.
% -----------------------------------------------------------------------------
betterof( Pos0, Val0, _Pos1, Val1, Pos0, Val0) :- % Pos0 better than Pos1
      min_to_move( Pos0),     % MIN to move in Pos0
      Val0 > Val1, !          % MAX prefers the greater value
      ; % Or
      max_to_move( Pos0),     % MAX to move in Pos0
      Val0 < Val1, !.         % MIN prefers the lesser value

betterof( _Pos0, _Val0, Pos1, Val1, Pos1, Val1). % Otherwise Pos1 better than Pos0


% -----------------------------------------------------------------------------
% auxMoves(+[Player, Board], -FinalBoard)
%
% Gera um estado sucessor para o jogador Player a partir do Board.
% Para cada combinação válida de (movimento + remoção de casa), produz um FinalBoard.
% Usada com findall em moves/2 para gerar todos os sucessores possíveis.
%
% Passos:
%   1. Localiza o peão do jogador no tabuleiro.
%   2. Testa cada uma das 8 direções possíveis (DX, DY ∈ {-1,0,1}, exceto (0,0)).
%   3. Verifica se o movimento é válido com isValidPlay.
%   4. Executa o movimento (apaga posição antiga, coloca na nova).
%   5. Via backtracking, escolhe cada casa vazia disponível e remove-a (marca com '#').
% -----------------------------------------------------------------------------
auxMoves([Player, Board], FinalBoard) :-
    indexOf(Board, Player, PosX, PosY), % Posição atual do peão

    % Gera todas as direções de movimento possíveis (8 direções)
    member(DX, [-1, 0, 1]),
    member(DY, [-1, 0, 1]),
    (DX \= 0 ; DY \= 0),   % Exclui o movimento nulo (ficar no lugar)

    NX is PosX + DX,
    NY is PosY + DY,

    % Verifica se o movimento para (NX, NY) é legal
    isValidPlay(NX, NY, Player, Board, PosX, PosY),

    % Executa o movimento: apaga peão da posição antiga e coloca na nova
    replaceTable(PosX, PosY, Board, '.', TempBoard1),
    replaceTable(NX, NY, TempBoard1, Player, TempBoard2),

    % Remove uma casa vazia (via backtracking, gera todas as combinações possíveis)
    indexOf(TempBoard2, '.', RemoveX, RemoveY),
    replaceTable(RemoveX, RemoveY, TempBoard2, '#', FinalBoard),

    % Filtra jogadas suicidas: não gera estados onde o próprio jogador fica bloqueado
    \+ isBlocked(Player, FinalBoard).


% -----------------------------------------------------------------------------
% moves(+[Player, Board], -PossibleMoveList)
%
% Gera a lista de todos os estados sucessores válidos a partir de [Player, Board].
% Falha se não existirem movimentos (lista vazia), indicando estado terminal.
%
% Usa findall para recolher todos os tabuleiros resultantes via auxMoves.
% O próximo jogador alterna: 'x' → 'o', 'o' → 'x'.
% -----------------------------------------------------------------------------
moves([Player, Board], PossibleMoveList) :-
    (Player == x -> NextPlayer = o ; NextPlayer = x), % Determina o próximo jogador
    findall([NextPlayer, NewBoard], auxMoves([Player, Board], NewBoard), PossibleMoveList),
    PossibleMoveList \= []. % Falha se não houver movimentos disponíveis


% -----------------------------------------------------------------------------
% min_to_move(+Pos) / max_to_move(+Pos)
%
% Determinam o papel do jogador no estado Pos:
%   min_to_move: 'x' é o minimizador (humano)
%   max_to_move: 'o' é o maximizador (computador)
% -----------------------------------------------------------------------------
min_to_move([x | _Tail]).
max_to_move([o | _Tail]).


% -----------------------------------------------------------------------------
% staticval(+[Player, Board], -Val)
%
% Avalia estaticamente um estado terminal (sem movimentos disponíveis).
% Apenas aplicável quando um dos jogadores está bloqueado.
%
%   Val = -1000 → 'o' está bloqueado (computador perdeu)
%   Val = +1000 → 'x' está bloqueado (humano perdeu, computador ganhou)
%
% Nota: ao contrário do alpha_beta.pl, esta versão não tem heurística para
% estados não terminais, tornando-a menos eficiente em jogos longos.
% -----------------------------------------------------------------------------
staticval([o, Board], -1000) :-
    countValidMoves(o, Board, 0), !.  % 'o' não tem movimentos: perdeu

staticval([x, Board], 1000) :-
    countValidMoves(x, Board, 0), !.  % 'x' não tem movimentos: ganhou (computador vence)


% -----------------------------------------------------------------------------
% countValidMoves(+Jogador, +Tabuleiro, -NumeroDeMovimentos)
%
% Conta o número de estados sucessores disponíveis para Jogador no Tabuleiro.
% Usa findall sobre auxMoves para gerar todos os movimentos possíveis e conta-os.
%
% Nota: esta abordagem gera tabuleiros completos para contar movimentos.
%       O alpha_beta.pl usa mobilidade/3 que é mais eficiente (conta apenas
%       células adjacentes válidas, sem gerar os tabuleiros resultantes).
% -----------------------------------------------------------------------------
countValidMoves(Jogador, Tabuleiro, NumeroDeMovimentos) :-
    findall([NextPlayer, NewBoard], auxMoves([Jogador, Tabuleiro], NewBoard), PossibleMoveList),
    (Jogador == x -> NextPlayer = o ; NextPlayer = x),
    length(PossibleMoveList, NumeroDeMovimentos).

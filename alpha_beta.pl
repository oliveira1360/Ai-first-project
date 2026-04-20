% =============================================================================
% alpha_beta.pl - Algoritmo Alpha-Beta Pruning com profundidade limitada
%
% Otimização do Minimax que poda ramos da árvore de jogo que não podem
% influenciar a decisão final, reduzindo drasticamente o número de estados
% avaliados sem perder a qualidade da jogada.
%
% Melhorias face ao minimax.pl:
%   - Limite de profundidade configurável (evita explosão combinatória)
%   - Função de avaliação estática melhorada com heurística de mobilidade
%     (não apenas valores terminais +1000/-1000)
%
% Convenção de papéis:
%   'x' → Minimizador (MIN) — o humano
%   'o' → Maximizador (MAX) — o computador
%
% Estado representado como: [Player, Board]
%   Player - jogador que vai jogar neste estado
%   Board  - tabuleiro atual (lista de listas)
% =============================================================================

% The alpha-beta algorithm

% -----------------------------------------------------------------------------
% alphabeta(+Pos, +Alpha, +Beta, -GoodPos, -Val, +CurrentDepth, +FinalDepth)
%
% Predicado central do Alpha-Beta Pruning.
%
% Argumentos:
%   Pos          - estado atual [Player, Board]
%   Alpha        - melhor valor garantido para o MAX (limite inferior)
%   Beta         - melhor valor garantido para o MIN (limite superior)
%   GoodPos      - melhor estado sucessor encontrado
%   Val          - valor minimax do estado Pos
%   CurrentDepth - profundidade atual na árvore de jogo
%   FinalDepth   - profundidade máxima de pesquisa (configura a dificuldade)
%
% Caso 1 (limite de profundidade atingido): avalia estaticamente com staticval.
% Caso 2 (há sucessores e profundidade disponível): explora com boundedbest.
% Caso 3 (sem sucessores — estado terminal): avalia estaticamente.
% -----------------------------------------------------------------------------
alphabeta(Pos, _, _, Pos, Val, Depth, Depth) :-
    !,
    staticval(Pos, Val).  % Caso 1: profundidade máxima atingida, avalia sem expandir

alphabeta(Pos, Alpha, Beta, GoodPos, Val, CurrentDepth, FinalDepth) :-
    CurrentDepth < FinalDepth,
    moves(Pos, PosList),  % Gera todos os sucessores válidos
    !,
    NextDepth is CurrentDepth + 1,
    % Explora os sucessores dentro dos limites alpha-beta
    boundedbest(PosList, Alpha, Beta, GoodPos, Val, NextDepth, FinalDepth).

alphabeta(Pos, _, _, Pos, Val, _, _) :-
    staticval(Pos, Val).  % Caso 3: estado terminal (sem movimentos), avalia estaticamente


% -----------------------------------------------------------------------------
% boundedbest(+[Pos|PosList], +Alpha, +Beta, -GoodPos, -GoodVal, +Depth, +Max)
%
% Avalia o primeiro candidato da lista e delega em goodenough/9 para decidir
% se continua a explorar os restantes ou poda o ramo.
% -----------------------------------------------------------------------------
boundedbest([Pos | PosList], Alpha, Beta, GoodPos, GoodVal, Depth, Max) :-
    alphabeta(Pos, Alpha, Beta, _, Val, Depth, Max), % Avalia o primeiro candidato
    goodenough(PosList, Alpha, Beta, Pos, Val, GoodPos, GoodVal, Depth, Max).


% -----------------------------------------------------------------------------
% goodenough(+PosList, +Alpha, +Beta, +Pos, +Val, -GoodPos, -GoodVal, +Depth, +Max)
%
% Decide se o candidato atual é suficientemente bom para parar (poda) ou
% se deve continuar a explorar os restantes candidatos.
%
% Caso base: lista vazia → o candidato atual é o melhor disponível.
%
% Poda do minimizador (x): se Val > Beta, MAX já tem uma opção melhor noutro ramo,
%   pelo que MIN nunca chegaria a este estado → poda.
%
% Poda do maximizador (o): se Val < Alpha, MIN já tem uma opção melhor noutro ramo,
%   pelo que MAX nunca chegaria a este estado → poda.
%
% Caso geral: atualiza os limites com newbounds e continua a explorar.
% -----------------------------------------------------------------------------

goodenough(_, _, _, Pos, Val, Pos, Val, _, _) :- 
    Val >= 1000, !.
goodenough(_, _, _, Pos, Val, Pos, Val, _, _) :- 
    Val =< -1000, !.

    
goodenough([], _, _, Pos, Val, Pos, Val, _, _) :- !. % Lista vazia: candidato atual é o melhor

goodenough(_, _Alpha, Beta, Pos, Val, Pos, Val, _, _) :-
    min_to_move(Pos), Val > Beta, !.  % Poda: MIN não escolheria este caminho
goodenough(_, Alpha, _Beta, Pos, Val, Pos, Val, _, _) :-
    max_to_move(Pos), Val < Alpha, !. % Poda: MAX não escolheria este caminho

goodenough(PosList, Alpha, Beta, Pos, Val, GoodPos, GoodVal, Depth, Max) :-
    % Sem poda: atualiza os limites e continua a explorar os restantes candidatos
    newbounds(Alpha, Beta, Pos, Val, NewAlpha, NewBeta),
    boundedbest(PosList, NewAlpha, NewBeta, Pos1, Val1, Depth, Max),
    betterof(Pos, Val, Pos1, Val1, GoodPos, GoodVal). % Retorna o melhor dos dois


% -----------------------------------------------------------------------------
% newbounds(+Alpha, +Beta, +Pos, +Val, -NewAlpha, -NewBeta)
%
% Atualiza os limites alpha e beta com base no valor encontrado:
%   - Se MIN jogou (x) e Val > Alpha → Alpha sobe para Val (maximizador melhorou)
%   - Se MAX jogou (o) e Val < Beta  → Beta desce para Val (minimizador melhorou)
%   - Caso contrário: os limites ficam inalterados
% -----------------------------------------------------------------------------
newbounds( Alpha, Beta, Pos, Val, Val, Beta) :-
	min_to_move( Pos), Val > Alpha, !.         % Maximizer increased lower bound

newbounds( Alpha, Beta, Pos, Val, Alpha, Val) :-
	max_to_move( Pos), Val < Beta, !.          % Minimizer decreased upper bound

newbounds( Alpha, Beta, _, _, Alpha, Beta). % Otherwise bounds unchanged


% -----------------------------------------------------------------------------
% betterof(+Pos, +Val, +Pos1, +Val1, -GoodPos, -GoodVal)
%
% Compara dois estados e devolve o melhor de acordo com o papel do jogador:
%   - Se MIN joga em Pos e Val > Val1 → Pos é melhor (MAX prefere valores maiores)
%   - Se MAX joga em Pos e Val < Val1 → Pos é melhor (MIN prefere valores menores)
%   - Caso contrário: Pos1 é melhor por defeito
% -----------------------------------------------------------------------------
betterof( Pos, Val, _Pos1, Val1, Pos, Val) :-   % Pos better than Pos1
	min_to_move( Pos), Val > Val1, !
	; % Or
	max_to_move( Pos), Val < Val1, !.

betterof( _, _, Pos1, Val1, Pos1, Val1). % Otherwise Pos1 better


% -----------------------------------------------------------------------------
% auxMoves(+[Player, Board], -FinalBoard)
%
% Gera sucessores com poda AGRESSIVA:
%   - Movimento: todas as 8 direções válidas do peão próprio
%   - Remoção: APENAS casas que são movimentos válidos do adversário
%     (garantia de impacto) E limitada às 4 melhores por estado
% -----------------------------------------------------------------------------
auxMoves([Player, Board], FinalBoard) :-
    (Player == x -> Opponent = o ; Opponent = x),

    indexOf(Board, Player, PosX, PosY),
    member(DX, [-1, 0, 1]),
    member(DY, [-1, 0, 1]),
    (DX \= 0 ; DY \= 0),
    NX is PosX + DX,
    NY is PosY + DY,
    isValidPlay(NX, NY, Player, Board, PosX, PosY),

    replaceTable(PosX, PosY, Board, '.', TempBoard1),
    replaceTable(NX, NY, TempBoard1, Player, TempBoard2),

    % Gera TODAS as remoções candidatas (casas válidas à volta do adversário)
    indexOf(TempBoard2, Opponent, OppX, OppY),
    findall(RX-RY,
        ( member(RDX, [-1, 0, 1]),
          member(RDY, [-1, 0, 1]),
          (RDX \= 0 ; RDY \= 0),
          RX is OppX + RDX,
          RY is OppY + RDY,
          isValidPlay(RX, RY, Opponent, TempBoard2, OppX, OppY)
        ),
        Candidates),

    % Escolhe UMA dessas candidatas (via backtracking)
   ( Candidates = [] ->
    indexOf(TempBoard2, '.', RemoveX, RemoveY)
    ;
        member(RemoveX-RemoveY, Candidates)
    ),
    replaceTable(RemoveX, RemoveY, TempBoard2, '#', FinalBoard),

    \+ isBlocked(Player, FinalBoard).



% getPos(+Board, +Row, +Col, ?Value) — lê o conteúdo da célula (Row, Col)
getPos(Board, Row, Col, Value) :-
    nth0(Row, Board, RowList),
    nth0(Col, RowList, Value).


% -----------------------------------------------------------------------------
% moves/2 — versão otimizada com ordenação por score
% -----------------------------------------------------------------------------
moves([Player, Board], OrderedList) :-
    (Player == x -> NextPlayer = o ; NextPlayer = x),

    findall(Score-[NextPlayer, NewBoard],
        ( auxMoves([Player, Board], NewBoard),
          % Localiza ambos os peões no NOVO board (uma vez por sucessor)
          indexOf(NewBoard, o, OX, OY),
          indexOf(NewBoard, x, XX, XY),
          staticval_fast(NewBoard, OX, OY, XX, XY, Score)
        ),
        ScoredList),

    ScoredList \= [],

    keysort(ScoredList, Ascending),
    ( NextPlayer == x ->
        reverse(Ascending, Sorted)
    ;
        Sorted = Ascending
    ),
    extract_positions(Sorted, OrderedList).

extract_positions([], []).
extract_positions([_-Pos | Rest], [Pos | RestPos]) :-
    extract_positions(Rest, RestPos).

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
% Função de avaliação estática melhorada (face ao minimax.pl).
%
% Estados terminais (um jogador bloqueado):
%   Val = -1000 → 'o' bloqueado (computador perdeu)
%   Val = +1000 → 'x' bloqueado (humano perdeu, computador ganhou)
%
% Estados não terminais (heurística de mobilidade):
%   Val = Mobilidade('o') - Mobilidade('x')
%   O computador tenta maximizar as suas opções e minimizar as do adversário.
%   Valores positivos favorecem o computador; negativos favorecem o humano.
% -----------------------------------------------------------------------------
staticval([o, Board], -1000) :- /*write('chegou ao final humano'), */ mobilidade(o, Board, 0), !. % 'o' não tem movimentos (Perdeu)
staticval([x, Board], 1000)  :- /*write('chegou ao final AI'),*/ mobilidade(x, Board, 0), !. % 'x' não tem movimentos (Ganhou)

staticval([_, Board], Val) :-
    mobilidade(o, Board, MovMax),
    mobilidade(x, Board, MovMin),
    Val is MovMax - MovMin. % Computador (o) quer maximizar as suas opções e minimizar as do jogador (x)


% -----------------------------------------------------------------------------
% mobilidade(+Player, +Board, -Count)
%
% Conta o número de movimentos válidos disponíveis para Player no Board.
% É usada como heurística na função de avaliação estática.
%
% Em vez de gerar tabuleiros com auxMoves, apenas conta as casas à volta
% que são válidas! (Máximo de 8 verificações em vez de dezenas)
%
% Mais eficiente que countValidMoves/3 do minimax.pl:
%   - Não gera os tabuleiros resultantes de cada remoção
%   - Apenas verifica a adjacência imediata do peão (≤ 8 verificações)
% -----------------------------------------------------------------------------
mobilidade(Player, Board, Count) :-
    indexOf(Board, Player, PosX, PosY), % Localiza o peão do jogador
    findall(1, (
        member(DX, [-1, 0, 1]),
        member(DY, [-1, 0, 1]),
        (DX \= 0 ; DY \= 0),           % Exclui a posição atual
        NX is PosX + DX,
        NY is PosY + DY,
        isValidPlay(NX, NY, Player, Board, PosX, PosY) % Conta apenas movimentos válidos
    ), ValidSpots),
    length(ValidSpots, Count). % O count é o número de movimentos válidos encontrados
% -----------------------------------------------------------------------------
% staticval com posições pré-calculadas — versão rápida para ordenação
%
% staticval_fast(+Board, +OPosX, +OPosY, +XPosX, +XPosY, -Val)
%
% Evita o custo de indexOf em cada chamada.
% -----------------------------------------------------------------------------
staticval_fast(Board, OX, OY, XX, XY, Val) :-
    mobilidade_at(o, Board, OX, OY, MovO),
    mobilidade_at(x, Board, XX, XY, MovX),
    ( MovO =:= 0 -> Val = -1000
    ; MovX =:= 0 -> Val =  1000
    ; Val is MovO - MovX
    ).


mobilidade_at(Player, Board, PX, PY, Count) :-
    aggregate_all(count, (
        member(DX, [-1, 0, 1]),
        member(DY, [-1, 0, 1]),
        (DX \= 0 ; DY \= 0),
        NX is PX + DX,
        NY is PY + DY,
        isValidPlay(NX, NY, Player, Board, PX, PY)
    ), Count).

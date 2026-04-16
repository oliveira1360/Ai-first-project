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
    member(DX, [-1, 0, 1]),
    member(DY, [-1, 0, 1]),
    (DX \= 0 ; DY \= 0),               % Exclui o movimento nulo (ficar no lugar)
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
staticval([o, Board], -1000) :- mobilidade(o, Board, 0), !. % 'o' não tem movimentos (Perdeu)
staticval([x, Board], 1000)  :- mobilidade(x, Board, 0), !. % 'x' não tem movimentos (Ganhou)

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

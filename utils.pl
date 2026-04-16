% =============================================================================
% utils.pl - Predicados utilitários do jogo ISOLA
%
% Contém as operações fundamentais sobre o tabuleiro:
%   - Localização de elementos (indexOf)
%   - Validação de jogadas (isValidPlay)
%   - Deteção de bloqueio (isBlocked)
%   - Colocação de obstáculos (putSharp / setupSharp)
%   - Auxiliares genéricos (first, second)
% =============================================================================


% -----------------------------------------------------------------------------
% indexOf(+Board, ?Element, ?Row, ?Col)
%
% Predicado bidirecional para acesso ao tabuleiro. Pode ser usado de três formas:
%
%   Como Localizador: dados Board e Element, devolve as coordenadas (Row, Col)
%                     onde o elemento se encontra. Faz backtracking se existirem
%                     várias ocorrências (ex: casas vazias '.').
%
%   Como Extrator:    dados Board, Row e Col, devolve o Element nessa posição
%                     (funciona como getter de célula).
%
%   Como Verificador: confirma se um elemento específico está numa posição exata.
%
% Usa nth0/3 (indexação com base 0) para percorrer linhas e colunas.
% -----------------------------------------------------------------------------
indexOf(Board, Element, Row, Col) :-
    nth0(Row, Board, RowList),   % Obtém a linha Row do tabuleiro
    nth0(Col, RowList, Element). % Obtém o elemento na coluna Col dessa linha


% -----------------------------------------------------------------------------
% isValidPlay(+X, +Y, +Player, +Board, ?OldX, ?OldY)
%
% Verifica se mover o peão de Player para a célula (X, Y) é uma jogada válida.
% Determina também a posição atual do peão (OldX, OldY).
%
% Condições de validade:
%   1. Localiza a posição atual do jogador no tabuleiro.
%   2. O destino (X, Y) contém uma casa vazia ('.').
%   3. O destino é adjacente (diferença de no máximo 1 em cada eixo).
%   4. O destino é diferente da posição atual (não pode ficar no mesmo lugar).
%
% Exemplo de teste: isValidPlay(0,0,[[x,#,.],[#,#,.],[.,.,o]]).
% -----------------------------------------------------------------------------
isValidPlay(X, Y, Player, Board, OldX, OldY) :-
    indexOf(Board, Player, OldX, OldY), % Localiza a posição atual do peão
    indexOf(Board, '.', X, Y),          % Confirma que o destino está vazio
    DiffX is OldX - X,
    DiffY is OldY - Y,
    member(DiffX, [-1, 0, 1]),          % Adjacência na direção das linhas
    member(DiffY, [-1, 0, 1]),          % Adjacência na direção das colunas
    \+ (OldX =:= X , OldY =:= Y).      % Garante que o peão se move de facto


% isBlocked(0,0,[[x,#,.],[#,#,.],[.,.,o]]).
% -----------------------------------------------------------------------------
% isBlocked(+Player, +Board)
%
% Tem sucesso se o jogador Player não tiver nenhum movimento válido disponível.
% Usa Negação por Falha (\+): tenta encontrar pelo menos uma jogada legal;
% se falhar em encontrar qualquer saída, confirma que o jogador está bloqueado.
%
% Um jogador bloqueado perde a partida imediatamente.
% -----------------------------------------------------------------------------
isBlocked(Player, Board) :-
    indexOf(Board, Player, PosX, PosY), % Localiza o peão do jogador
    \+ (
        % Tenta encontrar pelo menos uma direção válida para se mover
        member(DX, [-1, 0, 1]),
        member(DY, [-1, 0, 1]),
        NX is PosX + DX,
        NY is PosY + DY,
        isValidPlay(NX, NY, Player, Board, PosX, PosY)
    ).


% -----------------------------------------------------------------------------
% putSharp(+Board, +X, +Y, -NewBoard)
%
% Coloca um obstáculo '#' na posição (X, Y) do tabuleiro, gerando NewBoard.
% Falha se a célula (X, Y) não estiver vazia ('.'), impedindo remoções inválidas.
%
% Segue o princípio de imutabilidade do Prolog: não altera Board, cria uma
% nova versão do tabuleiro com o obstáculo inserido.
% -----------------------------------------------------------------------------
putSharp(Board, X, Y, NewBoard) :-
    indexOf(Board, '.', X, Y),          % Verifica que a célula está vazia
    replaceTable(X, Y, Board, '#', NewBoard). % Substitui '.' por '#'


% -----------------------------------------------------------------------------
% setupSharp(+Board, -NewBoard)
%
% Gere a interação com o humano para colocar um obstáculo '#' no tabuleiro.
% Pede ao utilizador as coordenadas, valida a escolha e gera NewBoard.
%
% Se a posição for inválida (ocupada ou fora do tabuleiro), recorre a si próprio
% recursivamente até que o utilizador introduza uma posição válida.
% Esta recursividade torna o predicado tolerante a erros de input humano.
% -----------------------------------------------------------------------------
setupSharp(Board, NewBoard) :-
    format('~nEscolha onde colocar um "#" (Row/Col): '),
    read(X/Y),  % Lê as coordenadas no formato Linha/Coluna
    (
        % Tenta colocar o obstáculo na posição indicada
        (putSharp(Board, X, Y, NewBoard)) ->
        (
            write('Obstaculo colocado!'), nl,
            printTable(NewBoard)
        )
        ;
        (
            % Posição inválida: informa o utilizador e repete o pedido
            write('Local ocupado ou invalido! Tente de novo.'), nl,
            setupSharp(Board, NewBoard)
        )
    ).


% -----------------------------------------------------------------------------
% first(?C, +List)
%
% Tem sucesso se C for o primeiro elemento da lista List.
% Equivalente a nth0(0, List, C).
% -----------------------------------------------------------------------------
first(C, [C|_]).


% -----------------------------------------------------------------------------
% second(?X, +List)
%
% Tem sucesso se X for o segundo elemento da lista List.
% Equivalente a nth0(1, List, X).
% -----------------------------------------------------------------------------
second(X, [_, X|_]).

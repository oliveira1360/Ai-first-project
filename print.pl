% =============================================================================
% print.pl - Impressão do tabuleiro no terminal
%
% Fornece predicados recursivos para visualizar o estado atual do tabuleiro.
% Cada linha é impressa com o índice da linha à esquerda, os elementos
% separados por espaços, e uma linha de cabeçalho com os índices das colunas.
% =============================================================================


% -----------------------------------------------------------------------------
% printColIndices(+I, +N)
%
% Imprime os índices das colunas de I até N-1, separados por espaços.
% Usado como cabeçalho do tabuleiro.
%
% Caso base: chegou ao fim (I = N) → imprime nova linha.
% Caso recursivo: imprime o índice I e avança para o seguinte.
% -----------------------------------------------------------------------------
printColIndices(N, N) :- nl.

printColIndices(I, N) :-
    I < N,
    format('~w ', [I]),  % Imprime o índice da coluna
    I1 is I + 1,
    printColIndices(I1, N).


% -----------------------------------------------------------------------------
% printList(+List, +RowIdx)
%
% Imprime todos os elementos de uma lista numa única linha, precedidos pelo
% índice da linha (RowIdx), com elementos separados por espaços.
%
% Caso base: lista vazia → imprime apenas nova linha.
% Caso recursivo: imprime a cabeça e processa o resto.
% -----------------------------------------------------------------------------
printList([], _) :- nl.

printList([H | T], _) :-
    write(H), write(' '),  % Imprime o elemento e um espaço separador
    printList(T, _).


% -----------------------------------------------------------------------------
% printRows(+Rows, +RowIdx)
%
% Imprime as linhas do tabuleiro uma a uma, com o índice da linha à esquerda.
%
% Caso base: sem mais linhas → termina.
% Caso recursivo: imprime o índice da linha, depois os elementos, e avança.
% -----------------------------------------------------------------------------
printRows([], _).

printRows([Row | Tail], RowIdx) :-
    format('~w ', [RowIdx]),  % Imprime o índice da linha
    printList(Row, RowIdx),
    NextIdx is RowIdx + 1,
    printRows(Tail, NextIdx).


% -----------------------------------------------------------------------------
% printTable(+Table)
%
% Imprime o tabuleiro completo com índices de linhas e colunas nas margens,
% tal como no enunciado do trabalho.
%
% Exemplo de saída (6x6):
%   0 1 2 3 4 5
% 0 x . . . . .
% 1 . . . . . .
% ...
% 5 . . . . . o
%
% Caso de tabuleiro vazio → não imprime nada.
% -----------------------------------------------------------------------------
printTable([]).

printTable(Board) :-
    Board = [FirstRow | _],
    length(FirstRow, NCols),  % Determina o número de colunas
    write('  '),              % Espaço de alinhamento para o cabeçalho
    printColIndices(0, NCols),% Imprime cabeçalho com índices das colunas
    printRows(Board, 0).      % Imprime cada linha com o seu índice

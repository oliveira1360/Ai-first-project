% =============================================================================
% replace.pl - Substituição de elementos em listas e tabuleiros
%
% Fornece predicados para modificar posições específicas de listas e matrizes
% (representadas como listas de listas) de forma imutável — isto é, os
% predicados não alteram as estruturas originais, mas geram novas versões.
% =============================================================================


% -----------------------------------------------------------------------------
% replace(+Idx, +List, +Value, -NewList)
%
% Substitui o elemento na posição Idx de List por Value, produzindo NewList.
% Usa indexação com base 0 (o primeiro elemento tem índice 0).
%
% Delega a lógica recursiva para replaceAux/5, iniciando com o contador em 0.
% -----------------------------------------------------------------------------
replace(Idx, List, Value, NewList) :-
    replaceAux(0, Idx, List, Value, NewList).


% -----------------------------------------------------------------------------
% replaceAux(+CurrentIdx, +TargetIdx, +List, +Value, -NewList)
%
% Caso base: o índice atual é igual ao índice alvo.
% Substitui a cabeça da lista pelo Value e mantém o resto (Tail) inalterado.
% -----------------------------------------------------------------------------
replaceAux(Idx, Idx, [_| Tail], Value, [Value | Tail]).

% -----------------------------------------------------------------------------
% Caso recursivo: o índice atual ainda não atingiu o alvo.
% Preserva a cabeça (H) e avança recursivamente para o próximo índice.
% -----------------------------------------------------------------------------
replaceAux(Idx1, Idx, [H | Tail], Value, [H | NewTail]) :-
    Idx1 =\= Idx,           % Idx1 != Idx: ainda não chegámos à posição alvo
    Idx2 is Idx1 + 1,
    replaceAux(Idx2, Idx, Tail, Value, NewTail).


% -----------------------------------------------------------------------------
% replaceTable(+Row, +Col, +Table, +Value, -NewTable)
%
% Substitui o valor na célula (Row, Col) da matriz Table por Value,
% produzindo NewTable. Usa indexação com base 0.
%
% Funcionamento:
%   1. Extrai a linha Row da tabela com nth0.
%   2. Substitui o elemento na coluna Col dessa linha com replace/4.
%   3. Substitui a linha antiga pela nova linha na tabela com replace/4.
% -----------------------------------------------------------------------------
replaceTable(Row, Col, Table, Value, NewTable) :-
    nth0(Row, Table, Line),              % Extrai a linha a modificar
    replace(Col, Line, Value, NewLine),  % Substitui o elemento na coluna
    replace(Row, Table, NewLine, NewTable). % Insere a linha modificada na tabela

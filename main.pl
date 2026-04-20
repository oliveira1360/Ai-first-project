% =============================================================================
% main.pl - Ponto de entrada e ciclo principal do jogo ISOLA
%
% Responsável por:
%   - Determinar qual o jogador ativo em cada turno
%   - Gerir a alternância entre jogador humano (x) e IA (o)
%   - Verificar condições de bloqueio (derrota)
%   - Chamar o algoritmo Alpha-Beta para as jogadas do computador
%   - Invocar setupSharp após cada jogada humana (remoção de casa)
% =============================================================================

% Carrega os módulos auxiliares necessários
:-consult('print.pl').
:-consult('replace.pl').
:-consult('utils.pl').
% :-consult('minimax.pl').   % Minimax desativado (muito lento em tabuleiros grandes)
:-consult('alpha_beta.pl').


% Exemplos de chamada para testes rápidos:
% play(0,[[x,.,.],[.,.,.],[.,.,o]]).
% play(0,[[x,.,.,.],[.,.,.,.],[.,.,.,.],[.,.,.,o]]).
% play(0,[[x,.,.,.,.,.],[.,.,.,.,.,.],[.,.,.,.,.,.],[.,.,.,.,.,.],[.,.,.,.,.,.],[.,.,.,.,.,o]]).

% -----------------------------------------------------------------------------
% play(+RoundNumber, +Board)
%
% Predicado principal do ciclo de jogo.
%   RoundNumber - número do turno atual (0, 1, 2, ...)
%   Board       - estado atual do tabuleiro (lista de listas)
%
% O jogador ativo é determinado pela paridade do turno:
%   par  → 'x' (humano)
%   ímpar → 'o' (computador / IA)
% -----------------------------------------------------------------------------
play(RoundNumber, Board) :-
    % Determina o jogador ativo com base na paridade do turno
    Resto is RoundNumber mod 2,
    (Resto =:= 0 -> Player = x ; Player = o),

    % Verifica se o jogador ativo está bloqueado (sem movimentos válidos)
    ( isBlocked(Player, Board) ->
        % Jogador bloqueado: imprime o tabuleiro final e declara a derrota
        ( nl, printTable(Board), format('~nPlayer ~w perdeu :(', [Player]), ! )
    ;
        % Jogador não bloqueado: executa a jogada correspondente ao jogador ativo
        ( Player == x ->
            % --- TURNO DO HUMANO ('x') ---
            nl, printTable(Board),
            format('~nRound ~w: Player ~w, enter move (Row/Col): ', [RoundNumber, Player]),
            read(X/Y),  % Lê a jogada no formato Linha/Coluna

            % Valida a jogada introduzida pelo utilizador
            ( isValidPlay(X, Y, Player, Board, OldRow, OldCol) ->
                (
                    % Move o peão: apaga a posição antiga e coloca o peão na nova posição
                    replaceTable(OldRow, OldCol, Board, '.', TempBoard),
                    replaceTable(X, Y, TempBoard, Player, UpdateTempBoard),
                    nl, printTable(UpdateTempBoard),

                    % Pede ao humano para remover uma casa do tabuleiro (marcada com '#')
                    setupSharp(UpdateTempBoard, NewBoard),

                    % Verifica se o humano se prendeu a si próprio com a sua própria jogada
                    ( isBlocked(Player, NewBoard) ->
                        ( nl, printTable(NewBoard), format('~nPlayer "~w" prendeu-se a si proprio', [Player]), ! )
                    ;
                        % Tudo válido: avança para o próximo turno
                        ( NextRound is RoundNumber + 1, play(NextRound, NewBoard) )
                    )
                )
            ;
                % Jogada inválida: repete o turno sem penalização
                ( write('Jogada invalida! Tente novamente.'), nl, play(RoundNumber, Board) )
            )

        % MINIMAX ('o') 
        /*
            nl, printTable(Board),
            format('~nRound ~w: O Computador (~w) esta a pensar...', [RoundNumber, Player]),
            minimax([Player, Board], [_NextPlayer, BestBoard], _Val),
            NextRound is RoundNumber + 1,
            play(NextRound, BestBoard)
        ) */

        % --- TURNO DO COMPUTADOR ('o') via ALPHA-BETA ---
        ;
            nl, printTable(Board),
            format('~nRound ~w: O Computador (~w) esta a pensar (Alpha-Beta)...', [RoundNumber, Player]),
            alphabeta([Player, Board], -10000, 10000, [_NextPlayer, BestBoard], Val, 0, 3),
            ( Val >= 1000 ->
            format('~nVitoria garantida encontrada! (Val=~w)', [Val])
            ; Val =< -1000 ->
            format('~nDerrota inevitavel detetada :( (Val=~w)', [Val])
            ;
                format('~nMelhor avaliacao: ~w', [Val])
            ),
            nl, printTable(BestBoard),

            % Verifica se o computador se bloqueou a si próprio com a sua jogada
            ( isBlocked(Player, BestBoard) ->
                ( format('~nPlayer "~w" prendeu-se a si proprio', [Player]), ! )
            ;
                ( NextRound is RoundNumber + 1, play(NextRound, BestBoard) )
            )
        )
    ).






% para humano vs humano
/*
( isBlocked(Player, Board) ->  
        ( nl, printTable(Board), format('~nPlayer ~w perdeu :(', [Player]), ! )
    ;
        (
            nl, printTable(Board),
            format('~nRound ~w: Player ~w, enter move (Row/Col): ', [RoundNumber, Player]),
           read(X/Y),
            ( ( isValidPlay(X, Y, Player, Board, OldRow, OldCol)) -> 
                (
                    replaceTable(OldRow, OldCol, Board, '.', TempBoard), 
                    replaceTable(X, Y, TempBoard, Player, UpdateTempBoard),
                    
                    nl, printTable(UpdateTempBoard),
                    setupSharp(UpdateTempBoard, NewBoard),
                    
                    ( isBlocked(Player, NewBoard) ->
                        ( nl, printTable(NewBoard), format('~nPlayer "~w" prendeu-se a si proprio', [Player]), ! )
                    ;
                        ( 
                            NextRound is RoundNumber + 1,
                            play(NextRound, NewBoard)
                        )
                    )
                )
            ; 
                (
                    write('Jogada invalida! Tente novamente.'), nl,
                    play(RoundNumber, Board)
                )
            )
        )
    ).
*/

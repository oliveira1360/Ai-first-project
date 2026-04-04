:-consult('print.pl').
:-consult('replace.pl').
:-consult('utils.pl').
% :-consult('minimax.pl').
:-consult('alpha_beta.pl').


% play(0,[[x,.,.],[.,.,.],[.,.,o]]).
% play(0,[[x,.,.,.,.,.],[.,.,.,.,.,.],[.,.,.,.,.,.],[.,.,.,.,.,.],[.,.,.,.,.,.],[.,.,.,.,.,o]]).
play(RoundNumber, Board) :-
    Xpto is RoundNumber mod 2,
    (Xpto =:= 0 -> Player = x ; Player = o),
    
    ( isBlocked(Player, Board) ->  
        ( nl, printTable(Board), format('~nPlayer ~w perdeu :(', [Player]), ! )
    ;
        ( Player == x ->
            nl, printTable(Board),
            format('~nRound ~w: Player ~w, enter move (Row/Col): ', [RoundNumber, Player]),
            read(X/Y),
            ( isValidPlay(X, Y, Player, Board, OldRow, OldCol) -> 
                (
                    replaceTable(OldRow, OldCol, Board, '.', TempBoard), 
                    replaceTable(X, Y, TempBoard, Player, UpdateTempBoard),
                    nl, printTable(UpdateTempBoard),
                    setupSharp(UpdateTempBoard, NewBoard),
                    
                    ( isBlocked(Player, NewBoard) ->
                        ( nl, printTable(NewBoard), format('~nPlayer "~w" prendeu-se a si proprio', [Player]), ! )
                    ;
                        ( NextRound is RoundNumber + 1, play(NextRound, NewBoard) )
                    )
                )
            ; 
                ( write('Jogada invalida! Tente novamente.'), nl, play(RoundNumber, Board) )
            )
            
        % MINIMAX ('o')
        %; 
            %nl, printTable(Board),
           % format('~nRound ~w: O Computador (~w) esta a pensar...', [RoundNumber, Player]),
          %  minimax([Player, Board], [_NextPlayer, BestBoard], _Val),
         %   NextRound is RoundNumber + 1,
        %    play(NextRound, BestBoard) 
        %)
        % ALPHA-BETA ('o')
        ; 
            nl, printTable(Board),
            format('~nRound ~w: O Computador (~w) esta a pensar (Alpha-Beta)...', [RoundNumber, Player]),
            % Chamada inicial: Alpha = -10000, Beta = 10000, Profundidade Inicial = 0, Profundidade Máxima = 3
            alphabeta([Player, Board], -10000, 10000, [_NextPlayer, BestBoard], _Val, 0, 2),
            NextRound is RoundNumber + 1,
            play(NextRound, BestBoard) 
        )
    ).
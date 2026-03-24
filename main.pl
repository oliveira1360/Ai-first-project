:-consult('print.pl').
:-consult('replace.pl').
:-consult('utils.pl').


% play(0,[[x,.,.],[.,.,.],[.,.,o]]).
play(RoundNumber, Board) :-
    Xpto is RoundNumber mod 2,
    (Xpto =:= 0 -> Player = x ; Player = o),
    
    ( isBlocked(Player, Board) ->  
        ( nl, printTable(Board), format('~nPlayer ~w perdeu! :(', [Player]), ! )
    ;
        (
            nl, printTable(Board),
            format('~nRound ~w: Player ~w, enter move (Row/Col): ', [RoundNumber, Player]),
            read(Input),
            ( (Input = X/Y, isValidPlay(X, Y, Player, Board, OldRow, OldCol)) -> 
                (
                    replaceTable(OldRow, OldCol, Board, '.', TempBoard), 
                    replaceTable(X, Y, TempBoard, Player, MidBoard),
                    
                    nl, printTable(MidBoard),
                    setupSharp(MidBoard, NewBoard),
                    
                    ( isBlocked(Player, NewBoard) ->
                        ( nl, printTable(NewBoard), format('~nPlayer ~w prendeu-se a si proprio e perdeu!', [Player]), ! )
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
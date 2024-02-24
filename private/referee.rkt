#lang racket

(module+ test)
(provide referee<%>
         referee%)

(require "./player.rkt"
         "./tic-tac-toe.rkt")

(define referee<%>
  (interface ()
    ; Game (listof Player) -> (values Game (listof Player))
    ; Play the game with the list of players.
    ; Return the final game state and the list of players that were kicked.
    play-game))

(define referee%
  (class* object% (referee<%>)
    (define/public (play-game gam players)
      (let loop ([gam gam] [players players])
        (define next-player)))))
;;; left off here doing referee

(define naive-player%
  (class* object% (player<%>)
    (define/public (get-move ))))

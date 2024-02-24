#lang racket

(provide player<%>)

;; Player interface

(define player<%>
  (interface ()
    ; Game -> Move
    ; Choose a move, given the current game state.
    get-move
    ; Game -> Void
    ; Called with the final game state when the game is over.
    notify-end))

(define naive-player%
  (class* object% (player<%>)
    (define/public (get-move ))))

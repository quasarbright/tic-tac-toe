#lang racket

(provide player<%>)

;; Player interface

(define player<%>
  (interface ()
    ; protocol is get-move get-move ... notify-end
    ; Game -> Move
    ; Choose a move, given the current game state.
    get-move
    ; Game -> Void
    ; Called with the final game state when the game is over.
    notify-end))

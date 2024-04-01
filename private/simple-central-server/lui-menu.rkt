#lang racket

(provide run-lui-menu)
(require "./client.rkt"
         "../lui-player.rkt")

(define (go)
    (define (return-to-menu)
      (displayln "game over, returning to main menu")
      (go))
    (newline)
    (displayln "1: host a game")
    (displayln "2: join a game")
    (displayln "3: play a local game")
    (displayln "q: quit")
    (newline)
    (display "tic-tac-toe> ")
    (match (read)
      [1 (host-game/lui) (return-to-menu)]
      [2 (join-game/lui) (return-to-menu)]
      [3 (run-local-lui-game) (return-to-menu)]
      ['q (displayln "goodbye!")]
      [_ (displayln "invalid input. please enter 1, 2, 3, or q")
         (go)]))

(define hostname "b-contents.gl.at.ply.gg")
(define port-no 48958)

(define (host-game/lui)
  (host-game hostname port-no (new lui-player%)))

(define (join-game/lui)
  (displayln "Enter game ID: ")
  (define game-id (symbol->string (read)))
  (join-game hostname port-no game-id (new lui-player%)))

(define (run-lui-menu)
  (displayln "welcome to tic-tac-toe!")
  (go))

(module+ main
  (run-lui-menu))

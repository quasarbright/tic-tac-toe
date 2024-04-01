#lang racket

;; command line main menu

(provide run-lui-menu)
(require "./lui-player.rkt"
         "./simple-central-server/lui-menu.rkt"
         "./host-game.rkt"
         "./join-game.rkt")

(define (go)
  (define (return-to-menu)
    (displayln "game over, returning to main menu")
    (go))
  (newline)
  (displayln "1: host a game")
  (displayln "2: join a game")
  (displayln "3: host a peer-to-peer game (requires ngrok)")
  (displayln "4: join a peer-to-peer game")
  (displayln "5: play a local game")
  (displayln "q: quit")
  (newline)
  (display "tic-tac-toe> ")
  (match (read)
    [1 (host-central-game) (return-to-menu)]
    [2 (join-central-game) (return-to-menu)]
    [3 (host-game) (return-to-menu)]
    [4 (join-game) (return-to-menu)]
    [5 (run-local-lui-game) (return-to-menu)]
    ['q (displayln "goodbye!")]
    [_ (displayln "invalid input. please enter 1, 2, 3, or q")
       (go)]))

(define (run-lui-menu)
  (displayln "welcome to tic-tac-toe!")
  (go))

(module+ main
  (run-lui-menu))

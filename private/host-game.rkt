#lang racket

(require "./server.rkt"
         "./referee.rkt"
         "./lui-player.rkt"
         "./tic-tac-toe.rkt")

(define (host-game)
  (displayln "launching server")
  (define server (new server%))
  (displayln "waiting for another player to join")
  (define remote-player (send server signup))
  (displayln "player joined. starting game.")
  (define human-player (new lui-player%))
  (define referee (new referee%))
  (send referee play-game INITIAL-GAME (list human-player remote-player))
  (send server close))

(module+ main
  (host-game))

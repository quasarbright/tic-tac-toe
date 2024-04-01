#lang racket

;; an online tic-tac-toe game featuring peer-to-peer and a central game server.

(require "./private/lui-menu.rkt")

(module+ main
  (run-lui-menu))

#lang racket

(require "./co-referee.rkt")

(define (join-game hostname port-no)
  (displayln "connecting to server")
  (define-values (in out) (tcp-connect hostname port-no))
  (define co-referee (new proxy-co-referee% [in in] [out out]))
  )

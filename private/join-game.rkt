#lang racket

(require "./co-referee.rkt"
         "./lui-player.rkt"
         "./join-code.rkt")

(define (join-game)
  (define-values (ip-address port-no) (get-decoded-join-code))
  (displayln "joining game")
  (define-values (in out) (tcp-connect ip-address port-no))
  (displayln "joined game, game starting")
  (define co-referee (new proxy-co-referee% [in in] [out out]))
  (define human-player (new lui-player%))
  (send co-referee play-game human-player))

(define (get-decoded-join-code)
  (display "enter join code: ")
  (define join-code (read-line))
  (with-handlers
    ([exn:fail? (lambda (_)
                  (displayln "invalid join code, try again")
                  (get-decoded-join-code))])
    (decode-join-code join-code)))

(module+ main
  (join-game))

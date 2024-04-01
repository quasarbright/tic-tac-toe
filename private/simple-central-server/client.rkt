#lang racket

(require "../player.rkt")
(provide
 (contract-out
  [host-game (-> string? listen-port-number? (is-a?/c player<%>) void?)]
  [join-game (-> string? listen-port-number? string? (is-a?/c player<%>) void?)]))
(require "../communication.rkt"
         "../json.rkt"
         "../co-referee.rkt")

(define (host-game hostname port-no player)
  (define-values (in out) (tcp-connect hostname port-no))
  (send-message (method-call->jsexpr "host-game") out)
  (define game-id (receive-message in))
  (displayln (format "game id: ~a" game-id))
  (play-game player in out))

(define (join-game hostname port-no game-id player)
  (define-values (in out) (tcp-connect hostname port-no))
  (send-message (method-call->jsexpr "join-game" game-id) out)
  (define joined? (jsexpr->boolean (receive-message in)))
  (if joined?
      (play-game player in out)
      (displayln "failed to join game")))

(define (play-game player in out)
  (define co-referee (new proxy-co-referee% [in in] [out out]))
  (send co-referee play-game player))

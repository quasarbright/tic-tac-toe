#lang racket

;; proxy co-referee for clients

(provide co-referee<%>
         proxy-co-referee%)
(require "./communication.rkt"
         "./json.rkt")

(define co-referee<%>
  (interface ()
    ; protocol: play-game END
    ; Player -> Void
    play-game))

(define proxy-co-referee%
  (class* object% (co-referee<%>)
    (super-new)
    (init-field in out)
    (define/public (play-game player)
      (let loop ()
        (match (receive-message in)
          [`("get-move" ,game-jsexpr)
           (send-message (move->jsexpr (send player get-move (jsexpr->game game-jsexpr))) out)
           (loop)]
          [`("notify-end" ,game-jsexpr)
           (send-message (void->jsexpr (send player notify-end (jsexpr->game game-jsexpr))) out)]
          [(? eof-object?) (displayln "disconnected from game")]
          [cmd (error "unknown command" cmd)]))
      (unless (port-closed? in)
        (close-input-port in))
      (unless (port-closed? out)
        (close-output-port out)))))

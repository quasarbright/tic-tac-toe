#lang racket

;; proxy co-referee for clients

(provide co-referee<%>
         proxy-co-referee%)
(require "./communication.rkt"
         "./json.rkt")

(define co-referee<%>
  (interface ()
    ; protocol: play-game END
    ; Player -> ?
    play-game))

(define proxy-co-referee%
  (class* object% (co-referee<%>)
    (super-new)
    (init-field in out)
    (define/public (play-game player)
      (let loop ()
        (send-message
         (match (receive-message in)
           [`("get-move" ,game-jsexpr)
            (move->jsexpr (send player get-move (jsexpr->game game-jsexpr)))
            (loop)]
           [`("notify-end" ,game-jsexpr)
            (void->jsexpr (send player notify-end (jsexpr->game game-jsexpr)))]
           [cmd (error "unknown command ~a" cmd)])))
      (close-input-port))))

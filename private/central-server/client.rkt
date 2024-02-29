#lang racket

(provide client<%>
         proxy-client%)
(require racket/random
         "../proxy-player.rkt")

; represents a user connected to the server
(define client<%>
  (interface ()
    ; -> String
    get-name
    ; -> Player
    get-player
    ; TODO notify lobby events
    ))

; the server's local representation of a remote user.
; communicates to the user via tcp.
(define proxy-client%
  (class* object% (client<%>)
    (super-new)

    (init-field
     ; input-port?
     in
     ; output-port?
     out
     ; CentralServer
     server)

    (define thd
      (thread
       (lambda ()
         (let loop ()
           ; TODO listen to lobby requests from in
           'todo))))

    ; TODO read name from in
    (define/public (get-name)
      (random-ref '("alice" "bob" "charlie" "david" "edward")))

    (define/public (get-player)
      (new proxy-player% [in in] [out out]))))

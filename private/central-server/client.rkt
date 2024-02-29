#lang racket

(provide client<%>
         proxy-client%)
(require racket/random
         "../proxy-player.rkt"
         "../communication.rkt"
         "../json.rkt")

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

    (define lobby #f)

    (define thd
      (thread
       (lambda ()
         (let loop ()
           (match (receive-message in)
             [(list "create-lobby")
              (set! lobby (send server create-lobby this))
              (define lobby-id (send lobby get-id))
              (send-message out lobby-id)
              (loop)]
             [(list "join-lobby" (and lobby-id (? string?)))
              (define maybe-lobby (send server get-lobby lobby-id))
              (cond
                [maybe-lobby
                 (set! lobby maybe-lobby)
                 (send lobby add-client! this)
                 (send-message out #t)
                 (loop)]
                [else
                 (send-message out #f)
                 (loop)])]
             [(list "leave-lobby")
              (when lobby
                (send lobby remove-client! this)
                (set! lobby #f))
              (send-message out (void->jsexpr (void)))
              (loop)]
             [(? eof-object?)
              (when lobby
                (send lobby remove-client! this))
              (void)]
             [msg (error 'proxy-client "unknown command ~a" msg)])))))

    (define/public (get-name)
      (send-message out (method-call->jsexpr "get-name"))
      (match (receive-message in)
        [(and name (? string?))
         name]
        [msg (error 'get-name "expected a name, received ~a" msg)]))

    (define/public (get-player)
      (new proxy-player% [in in] [out out]))))

#lang racket

(module+ test
  (require rackunit))
(module+ example
  (provide mock-client%))
(provide client<%>
         proxy-client%)
(require "../proxy-player.rkt"
         "../communication.rkt"
         "../json.rkt")

; represents a user connected to the server
(define client<%>
  (interface ()
    ; -> String
    ; currently unused
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
             [(list "create-lobby!")
              (set! lobby (send server create-lobby! this))
              (define lobby-id (send lobby get-id))
              (send-message lobby-id out)
              (loop)]
             [(list "join-lobby!" (and lobby-id (? string?)))
              (define maybe-lobby (send server get-lobby this lobby-id))
              (cond
                [maybe-lobby
                 (when lobby
                   (send lobby remove-client! this))
                 (set! lobby maybe-lobby)
                 (send lobby add-client! this)
                 (send-message #t out)
                 (loop)]
                [else
                 (send-message #f out)
                 (loop)])]
             [(list "leave-lobby!")
              (when lobby
                (send lobby remove-client! this)
                (set! lobby #f))
              (send-message (void->jsexpr (void)) out)
              (loop)]
             [(list "start-game!")
              (when lobby
                (send lobby start-game! this))
              (send-message (void->jsexpr (void)) out)
              (loop)]
             [(? eof-object?)
              (when lobby
                (send lobby remove-client! this))
              (void)]
             [msg (error 'proxy-client "unknown command ~a" msg)])))))

    (define/public (get-name)
      (send-message (method-call->jsexpr "get-name") out)
      (match (receive-message in)
        [(and name (? string?))
         name]
        [msg (error 'get-name "expected a name, received ~a" msg)]))

    (define/public (get-player)
      (new proxy-player% [in in] [out out]))

    (define/public (close)
      (kill-thread thd)
      (close-input-port in)
      (close-output-port out))))

(module+ example
  (require racket/random
           "../referee.rkt")
  (define mock-client%
    (class* object% (client<%>)
      (super-new)
      (define/public (get-name)
        (random-ref '("Alice" "Bob" "Charlie" "David" "Edward" "Frank")))
      (define/public (get-player) (new naive-player%)))))

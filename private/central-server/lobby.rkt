#lang racket

(provide lobby<%>
         lobby%)
(require racket/random
         "./thread-safe-list.rkt")

; where users connect with each other to play a game together
; a host creates a lobby, then other users join, then the host
; can start the game
(define lobby<%>
  (interface ()
    ; -> String
    get-id
    ; Client -> Void
    ; host sends itself for authz
    start-game!
    ; Client -> Void
    add-client!
    ; Client -> Void
    remove-client!))

(define lobby%
  (class* object% (lobby<%>)
    (super-new)
    (init-field
     ; Client
     host
     ; CentralServer
     ;server
     ; Referee
     referee)

    (define id (random-id))
    (define clients (make-tslist (list host)))
    (define (get-clients) (tslist-get-items clients))

    (define/public (get-id) id)

    (define/public (add-client! client)
      (unless (member client clients)
        (tslist-add! clients client)))

    (define/public (remove-client! client)
      (tslist-remove! clients client)
      (when (equal? client host)
        (for ([client (get-clients)])
          ; TODO notify client of disconnect
          (remove-client! client))))

    (define/public (start-game!)
      (send referee play-game (for/list ([client clients])
                                (send client get-player))))))

(define alphabet "abcdefghijklmnopqrstuvqxyz")

; -> String
(define (random-id [len 6])
  (apply string (random-sample alphabet len)))

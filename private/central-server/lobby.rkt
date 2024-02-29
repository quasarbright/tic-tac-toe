#lang racket

(provide lobby<%>
         lobby%)
(require racket/random)

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
    (define clients (list host))

    (define/public (get-id) id)

    (define/public (add-client! client)
      (unless (member client clients)
        (set! clients (cons client clients))))

    (define/public (remove-client! client)
      (set! clients (remove client clients)))

    (define/public (start-game!)
      (send referee play-game (for/list ([client clients])
                                (send client get-player))))))

(define alphabet "abcdefghijklmnopqrstuvqxyz")

; -> String
(define (random-id [len 6])
  (apply string (random-sample alphabet len)))

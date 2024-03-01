#lang racket

(module+ test (require rackunit))
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
      (unless (member client (tslist->list clients))
        (tslist-add! clients client)))

    (define/public (remove-client! client)
      (tslist-remove! clients client)
      (when (equal? client host)
        (define clients-list (tslist->list clients))
        (match clients-list
          [(cons client _)
           ; TODO notify host migration
           (set! host client)]
          [_
           (set! host #f)
           ; TODO shut down empty lobby, remove from server
           (void)])))

    (define/public (start-game! client)
      (when (equal? client host)
        ; TODO error if not host?
        (define players
          (for/list ([client (tslist->list clients)])
            (send client get-player)))
        (send referee play-game players)))))

(define alphabet "abcdefghijklmnopqrstuvqxyz")

; -> String
(define (random-id [len 6])
  (apply string (random-sample alphabet len)))

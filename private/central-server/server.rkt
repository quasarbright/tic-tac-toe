#lang racket

(provide central-server<%>
         central-server%)
(require racket/tcp
         "./client.rkt"
         "./lobby.rkt"
         "../referee.rkt"
         "./thread-safe-list.rkt")

; accepts clients and allows them to create and join lobbies
(define central-server<%>
  (interface ()
    ; Client -> Lobby
    ; host sends itself
    create-lobby!
    ; Client String -> (or/c #f Lobby)
    ; client sends itself. not currently necessary, but
    ; will be when public lobbies are a thing.
    get-lobby))

(define central-server%
  (class* object% (central-server<%>)
    (super-new)
    (define listener (tcp-listen 8090))
    (displayln "running local server at port 8090")

    (define clients (make-tslist))
    (define (add-client! client) (tslist-add! clients client))
    (define lobbies (make-tslist))
    (define (add-lobby! lobby) (tslist-add! lobby lobbies))
    (define (get-lobbies) (tslist-get-items lobbies))

    (define thd
      (thread
       (lambda ()
         (let loop ()
           (define-values (in out) (tcp-accept listener))
           (add-client!
            (new proxy-client%
                 [in in]
                 [out out]
                 [server this]))))))

    (define/public (create-lobby! host)
      (add-lobby!
       (new lobby%
            [host host]
            [referee (new referee%)])))

    (define/public (get-lobby client lobby-id)
      (define lobbies (get-lobbies))
      (findf (lambda (lobby) (equal? lobby-id (send lobby get-id)))
             lobbies))))

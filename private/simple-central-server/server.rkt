#lang racket

; simple central server
; after connecting, the client either says they want to join or host a game.
; the game eventually runs when someone joins it, then the clients are disconnected.

(provide
 ; -> Void
 run-server
 (struct-out client)
 ; host-game! : Client -> Void
 ; join-game! : Client String -> Void
 ; close! : -> Void
 ; get-port-no : -> listen-port-number?
 ; wait : -> Void
 server%)
(require racket/random
         "../communication.rkt"
         "../json.rkt"
         "../proxy-player.rkt"
         "../referee.rkt")

; A Client is a
(struct client [in out])
; where
; in is an input port
; out is an output port

(define server%
  (class object%
    (super-new)
    (init-field
     ; referee<%>
     [referee (new referee%)])

     ; (atom/c (hash/c string Client))
     ; maps game IDs to their hosts. only contains games that are waiting for someone to join.
    (define pending-games (make-hash))
    (define-values (listener port-no) (make-tcp-listener))
    (define thd
      (thread
       (lambda ()
         (let loop ()
           (displayln "accepting client")
           (define-values (in out) (tcp-accept listener))
           (displayln "accepted client")
           (define clnt (client in out))
           (match (receive-message in)
             [(list "host-game")
              (send this host-game! clnt)]
             [(list "join-game" game-id)
              (send this join-game! clnt game-id)])
           (loop)))))

    ; Client -> Void
    (define/public (host-game! clnt)
      (define game-id (random-id))
      (hash-set! pending-games game-id clnt)
      (displayln (format "hosting ~a" game-id))
      (send-message game-id (client-out clnt)))

    ; Client String -> Void
    ; join the game if it exists, run the game, and close the connections of both players.
    ; game runs in a separate thread.
    (define/public (join-game! clnt game-id)
      (define host (hash-ref pending-games game-id (lambda () #f)))
      (send-message (boolean->jsexpr (not (not host))) (client-out clnt))
      (when host
        (displayln (format "joining ~a" game-id))
        (hash-remove! pending-games game-id)
        (thread
         (lambda ()
           (define host-player (client->player host))
           (define joiner-player (client->player clnt))
           (send referee play-game (list host-player joiner-player))
           (client-close! host)
           (client-close! clnt)))))

    ; Void
    (define/public (close!)
      (kill-thread thd)
      (for ([(_ host) (in-hash pending-games)])
        (client-close! host))
      (tcp-close listener))

    ; -> listen-port-number?
    (define/public (get-port-no) port-no)

    ; -> Void
    (define/public (wait) (thread-wait thd))))

; Client -> Player
(define (client->player clnt)
  (match clnt
    [(client in out) (new proxy-player% [in in] [out out])]))

; Client -> Void
(define (client-close! clnt)
  (match clnt
    [(client in out)
     (close-input-port in)
     (close-output-port out)]))

(define alphabet "abcdefghijklmnopqrstuvqxyz")

; -> String
(define (random-id [len 6])
  (apply string (random-sample alphabet len)))

; -> (values tcp-listener? listen-port-number?)
(define (make-tcp-listener)
  ; have to use 8090 bc of playit.gg
  (values (tcp-listen 8090) 8090))

(define (run-server)
  (define server (new server%))
  (define port-no (send server get-port-no))
  (displayln (format "server running at port ~a" port-no))
  (send server wait))

(module+ main
  (run-server))

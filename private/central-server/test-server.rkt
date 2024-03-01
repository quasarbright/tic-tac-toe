#lang racket

; tests the server side: server, lobby, and client

(module+ test
  (require rackunit
           "./server.rkt"
           "./client.rkt"
           "./lobby.rkt"
           "../communication.rkt"
           "../json.rkt"
           "../tic-tac-toe.rkt")
  ; CentralServer -> (values ProxyClient (-> jsexpr? void?) (-> jsexpr?))
  (define (make-test-client server)
    ; client~>server-in is read from by the server
    ; we write to client~>server-out for testing
    (define-values (client~>server-in client~>server-out) (make-pipe))
    ; server~>client-out is written to by the server
    ; we read from server~>client-in for testing
    (define-values (server~>client-in server~>client-out) (make-pipe))
    (define (send-as-client msg) (send-message msg client~>server-out))
    (define (receive-as-client) (receive-message server~>client-in))
    (define client
      (new proxy-client%
           [in client~>server-in]
           [out server~>client-out]
           [server server]))
    (values client send-as-client receive-as-client))

  (test-case "happy path"
    (define server (new central-server%))
    (after
     (define-values (alice send-as-alice receive-as-alice) (make-test-client server))
     (send server add-client!/testing alice)
     (define-values (bob send-as-bob receive-as-bob) (make-test-client server))
     (send server add-client!/testing bob)

     (send-as-alice (method-call->jsexpr "create-lobby!"))
     (define lobby-id (receive-as-alice))
     (check-pred string? lobby-id)

     (send-as-bob (method-call->jsexpr "join-lobby!" lobby-id))
     (check-equal? (receive-as-bob) #t)

     (send-as-alice (method-call->jsexpr "start-game!"))

     ; freezing here.
     ; the client and the player are both reading from the same input port,
     ; which is probably causing the problem. they're probably getting kicked and then
     ; still expecting messages.
     ; client reads user commands from user
     ; client writes results to user
     ; player writes referee commands to user
     ; player reads user responses
     ;
     ; do you need a layer of indirection on the ports and a router for messages?

     ; wait a minute, the call to start-game! blocks until it's done! so something else is going on

     (check-match (receive-as-alice)
                  (cons "get-move" _))
     (send-as-alice (move->jsexpr (position 0 0)))

     (check-match (receive-as-bob)
                  (cons "get-move" _))
     (send-as-bob (move->jsexpr (position 1 0)))

     (check-match (receive-as-alice)
                  (cons "get-move" _))
     (send-as-alice (move->jsexpr (position 0 1)))

     (check-match (receive-as-bob)
                  (cons "get-move" _))
     (send-as-bob (move->jsexpr (position 1 1)))

     (check-match (receive-as-alice)
                  (cons "get-move" _))
     (send-as-alice (move->jsexpr (position 0 2)))

     ; the order of notify-end is weird but it doesn't matter
     (check-match (receive-as-bob)
                  (cons "notify-end" _))
     (send-as-bob (void->jsexpr (void)))

     (check-match (receive-as-alice)
                  (cons "notify-end" _))
     (send-as-alice (void->jsexpr (void)))

     ; from the lobby start-game!
     (check-equal? (receive-as-alice)
                   (void->jsexpr (void)))

     (send-as-bob (method-call->jsexpr "leave-lobby!"))
     (check-equal? (receive-as-bob)
                   (void->jsexpr (void)))

     (send-as-alice (method-call->jsexpr "leave-lobby!"))
     (check-equal? (receive-as-alice)
                   (void->jsexpr (void)))

     ; cleanup
     (send server close))

    (test-case "host leave lobby")
    (test-case "join lobby while in lobby")
    (test-case "empty lobby gets removed")))

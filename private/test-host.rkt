#lang racket

;; testing out a basic tcp server

(require racket/tcp
         hostname)

(define ip-address (first (get-ipv4-addrs #:normal? #t #:localhost? #f)))

(displayln "launching server")
(define listener (tcp-listen 8090))
(displayln "waiting for client")
(define-values (in out) (tcp-accept listener))
(displayln "accepted client")
(displayln "ping" out)
(flush-output out)
(displayln (format "Received message from client: ~a" (read in)))
(close-input-port in)
(close-output-port out)
(tcp-close listener)

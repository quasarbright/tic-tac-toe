#lang racket

;; testing out a basic tcp client

(require racket/tcp
         hostname)

(define ip-address (first (get-ipv4-addrs #:normal? #t #:localhost? #f)))

(displayln "connecting to server")
(define-values (in out) (tcp-connect ip-address 8090))
(displayln "connected to server")
(displayln (format "Received message from server: ~a" (read in)))
(displayln "pong" out)
(flush-output out)
(close-input-port in)
(close-output-port out)

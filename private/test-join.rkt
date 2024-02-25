#lang racket

;; testing out a basic tcp client

(require racket/tcp
         net/base64
         json)

(display "Enter join code: ")
(define join-token/enc (read-line))
(define join-token
  (string->jsexpr
   (bytes->string/utf-8
    (base64-decode
     (string->bytes/utf-8 join-token/enc)))))
(match-define (list ip-address port) join-token)

(displayln "connecting to server")
(define-values (in out) (tcp-connect ip-address port))
(displayln "connected to server")
(displayln (format "Received message from server: ~a" (read in)))
(displayln "pong" out)
(flush-output out)
(close-input-port in)
(close-output-port out)

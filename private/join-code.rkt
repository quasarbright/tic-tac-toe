#lang racket

;; utilities for working with join codes, which opaquely represent the information needed to join a game

(module+ test (require rackunit))
(provide (contract-out
          [make-join-code (-> string? natural? string?)]
          [decode-join-code (-> string? (values string? natural?))]))

(require net/base64
         json)

; a join code is a base64 encoded string representing the ip address and port number of the host server.
; specifically, the data is represented as a json like ["127.0.0.1", 8080], stringified, and then base64 encoded.

; string? port-number? -> string?
; create an encoded join code
(define (make-join-code ip-address port-no)
  (bytes->string/utf-8
   (base64-encode
    (string->bytes/utf-8
     (jsexpr->string
      (list ip-address port-no))))))

; string? -> (values string? port-number?)
; decode an encoded join code and return the data
(define (decode-join-code join-code)
  (match
      (string->jsexpr
       (bytes->string/utf-8
        (base64-decode
         (string->bytes/utf-8 join-code))))
    [(list ip-address port-no) (values ip-address port-no)]
    [_ (error 'decode-join-code "invalid join code")]))

(module+ test
  (define ip-address "127.0.0.1")
  (define port-no 8080)
  (define join-code (make-join-code ip-address port-no))
  (define-values (ip-address^ port-no^) (decode-join-code join-code))
  (check-equal? ip-address^ ip-address)
  (check-equal? port-no^ port-no))

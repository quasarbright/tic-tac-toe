#lang racket

;; Helpers for communicating with JSON over the wire

(require json)

(provide (contract-out
          ;; Send json over the wire
          [send-message (->* (jsexpr?) (output-port?) void?)]
          ;; Receive json over the wire
          [receive-message (->* () (input-port?) (or/c jsexpr? eof-object?))]))

(define (send-message json [out (current-output-port)])
  (parameterize ([current-output-port out])
    (write-json json)
    (newline)
    (flush-output)))

(define (receive-message [in (current-input-port)])
  (parameterize ([current-input-port in])
    (read-json)))

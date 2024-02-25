#lang racket

;; testing out a basic tcp server

(require racket/tcp
         nat-traversal
         net/base64
         json)

(define (get-ip-address)
  (if (eq? 'windows (system-type 'os))
      (get-ip-address/windows)
      (best-interface-ip-address)))

(define (get-ip-address/windows)
  (define output
    (with-output-to-string
      (lambda ()
        (system "ipconfig | findstr /i \"ipv4\""))))
  (define addresses (regexp-match* #px"(\\d+\\.)+\\d+" output))
  (when (null? addresses)
    (error 'get-ip-address "unable to find ip address"))
  (first addresses))

(displayln "launching server")

; -> (values tcp-listener? port-number?)
(define (make-tcp-listener)
  (let loop ([port-no 8090])
    (when (> port-no 9000)
      (error 'make-tcp-listener "unable to find a good port to launch the server"))
    (with-handlers
      ([exn:fail:network? (lambda (_) (loop (add1 port-no)))])
      (values (tcp-listen port-no) port-no))))
(define-values (listener port) (make-tcp-listener))
(displayln (format "server running at port ~a" port))
(define ip-address (get-ip-address))
(define join-info (jsexpr->string (list ip-address port)))
(define join-info/enc (base64-encode (string->bytes/utf-8 join-info)))
(displayln (format "join code: ~a" join-info/enc))
(displayln "waiting for client")
(define-values (in out) (tcp-accept listener))
(displayln "accepted client")
(displayln "ping" out)
(flush-output out)
(displayln (format "Received message from client: ~a" (read in)))
(close-input-port in)
(close-output-port out)
(tcp-close listener)

#lang racket

;; utilities for working with ngrok
;; https://ngrok.com/
;; for our purposes, it's a reverse proxy that makes
;; our tcp server public.

(provide (contract-out
          [launch-ngrok-server (-> port-number? (values string? port-number?))]))
(require net/url
         json)

; port-number? -> (values string? port-number?)
; launch an ngrok tcp server that listens to the given port
; number on this machine.
; returns the domain and port number of the public ngrok tcp server.
(define (launch-ngrok-server port-no)
  ; ensure the subprocess gets killed if this program ends
  (current-subprocess-custodian-mode 'kill)
  (define-values (sp out in err)
    (subprocess #f #f (current-error-port)
                (path-to-ngrok) "tcp" (number->string port-no 10) "--log" "stdout" "--log-format" "json"))
  (let loop ()
    ; TODO handle non-json. can happen when ngrok is already running, for example.
    (define js (read-json out))
    (match js
      [(hash-table ('msg "started tunnel") ('url url-str))
       (define url (string->url url-str))
       (define host (url-host url))
       (define port-no (url-port url))
       (values host port-no)]
      [(? eof-object?) (error 'get-public-connection-info "unable to get public connection info")]
      [_ (loop)])))

; -> string?
; return the path to the ngrok executable
(define (path-to-ngrok)
  (define result #f)
  (define cmd
    (match (system-type 'os)
      ['windows "where ngrok"]
      [_ "which ngrok"]))
  (define output
    (with-output-to-string
      (lambda ()
        (set! result (system cmd)))))
  (unless result (error 'locate-ngrok "unable to locate ngrok executable. is it installed?"))
  (string-trim output))

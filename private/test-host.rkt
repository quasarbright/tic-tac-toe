#lang racket

;; testing out a basic tcp server

(require racket/tcp
         nat-traversal
         net/base64
         net/url
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

; -> string?
; return the path to the ngrok executable
(define (locate-ngrok)
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

; port-number? -> (values string? port-number?)
; runs ngrok at the specified port number on this machine,
; returns the domain and port number of the public ngrok tcp server
(define (get-public-connection-info port-no)
  (define-values (sp out in err)
    (subprocess #f #f (current-error-port) (locate-ngrok) "tcp" (number->string port-no 10) "--log" "stdout" "--log-format" "json"))
  (let loop ()
    (define js (read-json out))
    (match js
      [(hash-table ('msg "started tunnel") ('url url-str))
       (define url (string->url url-str))
       (define host (url-host url))
       (define port-no (url-port url))
       (values host port-no)]
      [(? eof-object?) (error 'get-public-connection-info "unable to get public connection info")]
      [_ (loop)])))

(define (make-tcp-listener)
  (let loop ([port-no 8090])
    (when (> port-no 9000)
      (error 'make-tcp-listener "unable to find a good port to launch the server"))
    (with-handlers
      ([exn:fail:network? (lambda (_) (loop (add1 port-no)))])
      (values (tcp-listen port-no) port-no))))

(module+ main
  (displayln "launching server")
  (current-subprocess-custodian-mode 'kill)
  (define-values (listener private-port-no) (make-tcp-listener))
  (define-values (public-address public-port-no) (get-public-connection-info private-port-no))
  (displayln (format "server running at ~a:~a using private port ~a"
                     public-address
                     public-port-no
                     private-port-no))
  (define join-info (jsexpr->string (list public-address public-port-no)))
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
  (tcp-close listener))

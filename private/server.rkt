#lang racket

(provide server<%>
         tcp-server%)
(require "./proxy-player.rkt")

(define server<%>
  (interface ()
    ; protocol is signup signup ... close END
    ; -> Player
    signup
    ; -> Void
    close))

(define tcp-server%
  (class* object% (server<%>)
    (super-new)

    (define-values (listener port-no) (make-tcp-listener))
    (define ins '())
    (define outs '())
    (define/public (signup)
      (define-values (in out) (tcp-accept listener))
      (set! ins (cons in ins))
      (set! outs (cons out outs))
      (new proxy-player% [in in] [out out]))
    (define/public (close)
      (tcp-close listener)
      (for ([in ins])
        (close-input-port in))
      (for ([out outs])
        (close-output-port out)))
    ; -> port-number?
    (define/public (get-port-no) port-no)))

(define (make-tcp-listener)
  (let loop ([port-no 8090])
    (when (> port-no 9000)
      (error 'make-tcp-listener "unable to find a good port to launch the server"))
    (with-handlers
      ([exn:fail:network? (lambda (_) (loop (add1 port-no)))])
      (values (tcp-listen port-no) port-no))))

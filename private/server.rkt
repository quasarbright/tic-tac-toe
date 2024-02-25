#lang racket

(provide server<%>
         DEFAULT_PORT_NO
         server%)
(require "./proxy-player.rkt")

(define server<%>
  (interface ()
    ; protocol is signup signup ... close END
    ; -> Player
    signup
    ; -> Void
    close))

(define DEFAULT_PORT_NO 8024)

(define server%
  (class* object% (server<%>)
    (super-new)
    (init-field [port-no DEFAULT_PORT_NO])
    (define listener (tcp-listen port-no 1))
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
        (close-output-port out)))))

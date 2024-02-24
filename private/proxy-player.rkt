#lang racket

;; proxy player that sends game states and receives moves over ports

(module+ test (require rackunit))
(provide proxy-player%)

(require "./player.rkt"
         "./json.rkt"
         "./communication.rkt"
         (for-syntax syntax/parse))

(define proxy-player%
  (class* object% (player<%>)
    (super-new)
    (init-field
     ; input-port?
     in
     ; output-port?
     out)
    (define-syntax define/remote
      (syntax-parser
        [(_ method-name:id (arg->jsexpr:expr ...) jsexpr->ret:expr)
         (define/syntax-parse (arg ...) (generate-temporaries #'(arg->jsexpr ...)))
         #'(define/public (method-name arg ...)
             (send-message (method-call->jsexpr (symbol->string 'method-name) (arg->jsexpr arg) ...)
                           out)
             (jsexpr->ret (receive-message in)))]))
    (define/remote get-move (game->jsexpr) jsexpr->move)
    (define/remote notify-end (game->jsexpr) jsexpr->void)))

(module+ test
  (require json
           "./tic-tac-toe.rkt")
  (define game-json-string
   (with-input-from-string "[0, 0]"
     (lambda ()
       (with-output-to-string
         (lambda ()
           (define player (new proxy-player% [in (current-input-port)] [out (current-output-port)]))
           (check-equal? (send player get-move INITIAL-GAME)
                         (position 0 0)))))))
  (check-equal? (string->jsexpr game-json-string)
                (list "get-move" (hasheq 'grid '((null null null) (null null null) (null null null))
                                         'next-player "X"))))

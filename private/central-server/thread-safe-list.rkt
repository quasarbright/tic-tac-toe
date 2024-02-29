#lang racket

; A list which can be manipulated concurrently.
; requests can be sent in parallel, but are processed serially.
; update operations block until they are processed and completed.
; inspired by actor model.

; TODO implement a more general "atom" construct
; which is any value that you can concurrently modify
; and read, and make this a thin wrapper around it

(module+ test (require rackunit))
(provide tslist?
         (contract-out
          ; TODO higher order contract with element contract
          [make-tslist (-> (listof any/c) tslist?)]
          [tslist-add! (-> any/c tslist? void?)]
          [tslist-remove! (-> any/c tslist? void?)]
          [tslist-get-items (-> tslist? (listof any/c))]
          ; alias of tslist-get-items
          [tslist->list (-> tslist? (listof any/c))]))

(require racket/async-channel)

; TODO on-change listeners?

(struct tslist
  ; (listof any) - the items
  [(lst #:mutable)
   ; Thread - event loop that processes commands
   thd
   ; Channel - for commands
   chan])

(define (make-tslist [lst '()])
  (define chan (make-async-channel))
  ; TODO i don't think this can get garbage-collected
  (define tsl
    (tslist lst
            (thread
             (lambda ()
               (let loop ()
                 ; assumes this never errors.
                 (match (async-channel-get chan)
                   ; accepts messages of the form
                   ; (list (-> (listof any) (listof any)) (-> any any))
                   ; where f is the modification to the list and
                   ; k is the callback for the result, which in our case is always void
                   [(list f k)
                    (k (set-tslist-lst! tsl (f (tslist-lst tsl))))])
                 (loop))))
            chan))
  tsl)

; TSList Any -> Void
; add the value to the list, blocks until complete
(define (tslist-add! tsl v)
  (with-async k
    (async-channel-put (tslist-chan tsl)
                       (list (lambda (lst) (cons v lst))
                             k))))

; TSList Any -> Void
; remove the value from the list if present.
; does nothing otherwise.
; blocks until complete
(define (tslist-remove! tsl v)
  (with-async k
    (async-channel-put (tslist-chan tsl)
                       (list (lambda (lst) (remove v lst))
                             k))))

; TSLIst -> (listof any)
; get the items in the list.
; doesn't wait for pending modifications or anything like that
(define (tslist-get-items tsl)
  (tslist-lst tsl))

; alias for tslist-get-items
(define (tslist->list tsl)
  (tslist-get-items tsl))

; runs body, which kicks off some async process
; which will call k exactly once with its result.
; blocks until k is called.
; whole form evaluates to the argument of k.
(define-syntax-rule
  (with-async k body ...)
  (let ()
    (define result-chan (make-channel))
    (let ([k (lambda (result) (channel-put result-chan result))])
      body
      ...
      (channel-get result-chan))))

(module+ test
  ; ensure concurrent updates are all processed properly
  ; this would fail with normal lists
  (define tsl (make-tslist))
  (define N 1000)
  (for/async ([n (in-range N)])
    (tslist-add! tsl n))
  (check-equal? (length (tslist->list tsl))
                N)
  (for/async ([n (in-range N)])
    (tslist-remove! tsl n))
  (check-equal? (length (tslist->list tsl))
                0))

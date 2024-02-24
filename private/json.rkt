#lang racket

(require json)
(provide
 (contract-out
  [game->jsexpr (-> game? jsexpr?)]
  [jsexpr->move (-> jsexpr? move?)]
  [jsexpr->void (-> jsexpr? void?)]
  [method-call->jsexpr (->* (string?) #:rest (listof jsexpr?) jsexpr?)]))
(require "./tic-tac-toe.rkt")

; Game -> JSExpr
(define (game->jsexpr gam)
  (hasheq 'grid (for/list ([row '(0 1 2)])
                  (for/list ([col '(0 1 2)])
                    (define cell (game-get-cell gam (position row col)))
                    (if cell
                        (symbol->string cell)
                        'null)))
          'next-player (symbol->string (game-next-player gam))))

; JSExpr -> Move
(define (jsexpr->move js)
  (match js
    [(list row col)
     (unless (and (natural? row)
                  (natural? col)
                  (<= 0 row 2)
                  (<= 0 col 2))
       (error 'jsexpr->move "invalid move"))
     (position row col)]
    [_
     (error 'jsexpr->move "invalid move")]))

; JSExpr -> Void
(define (jsexpr->void js)
  (match js
    ["void" (void)]
    [_ (error 'jsexpr->void "invalid void")]))

; String JSExpr ... -> JSExpr
(define (method-call->jsexpr method-name . args)
  (cons method-name args))

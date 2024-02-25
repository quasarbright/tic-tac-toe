#lang racket

(require json)
(provide
 (contract-out
  [game->jsexpr (-> game? jsexpr?)]
  [jsexpr->game (-> jsexpr? game?)]
  [jsexpr->move (-> jsexpr? move?)]
  [move->jsexpr (-> move? jsexpr?)]
  [jsexpr->void (-> jsexpr? void?)]
  [void->jsexpr (-> void? jsexpr?)]
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

; JSExpr -> Game
(define (jsexpr->game game-jsexpr)
  (match game-jsexpr
    [(hash-table ('grid grid-jsexpr) ('next-player next-player-jsexpr))
     (game (for/list ([row-jsexpr grid-jsexpr])
             (for/list ([cell-jsexpr row-jsexpr])
               (match cell-jsexpr
                 ["X" 'X]
                 ["O" 'O]
                 ['null #f]
                 [_ (error "invalid cell ~a" cell-jsexpr)])))
           (match next-player-jsexpr
             ["X" 'X]
             ["O" 'O]
             [_ (error "invalid next player ~a" next-player-jsexpr)]))]))

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

; Move -> JSExpr
(define (move->jsexpr mov)
  (match mov
    [(position row col)
     (list row col)]))

; JSExpr -> Void
(define (jsexpr->void js)
  (match js
    ["void" (void)]
    [_ (error 'jsexpr->void "invalid void")]))

; Void -> JSExpr
(define (void->jsexpr v) "void")

; String JSExpr ... -> JSExpr
(define (method-call->jsexpr method-name . args)
  (cons method-name args))

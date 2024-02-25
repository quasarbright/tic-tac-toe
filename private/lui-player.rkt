#lang racket

;; human player via command-line

(provide lui-player%)

(require "./player.rkt"
         "./tic-tac-toe.rkt")

(define lui-player%
  (class* object% (player<%>)
    (super-new)
    (define/public (get-move gam)
      (newline)
      (display-game gam)
      (read-move))
    (define/public (notify-end gam)
      (newline)
      (display-game-end gam))))

; Game -> Void
(define (display-game gam [display-turn? #t])
  (when display-turn?
    (displayln (format "It is ~a's turn" (game-next-player gam))))
  (for ([row '(0 1 2)])
    (for ([col '(0 1 2)])
      (define cell (game-get-cell gam (position row col)))
      (display (or cell "-")))
    (displayln "")))

(define (display-game-end gam)
  (define winner (game-get-winner gam))
  (displayln
   (if winner
       (format "~a won!" winner)
       "draw"))
  (display-game gam #f))

; -> Move
(define (read-move)
  ; TODO retry logic
  (display "Enter a move as two numbers in parentheses, like (0 0) for top-left: ")
  (define move-datum (read))
  (match move-datum
    [(list (and row (? valid-coord?)) (and col (? valid-coord?)))
     (position row col)]
    [_
     (displayln "Invalid move, try again.")
     (read-move)]))

(define (valid-coord? v) (and (natural? v) (<= 0 v 2)))

(module+ main
  (require "./referee.rkt")
  (define lui-player (new lui-player%))
  (define lui-player-2 (new lui-player%))
  (define referee (new referee%))
  (void (send referee play-game INITIAL-GAME (list lui-player lui-player-2))))

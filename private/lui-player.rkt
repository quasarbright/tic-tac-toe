#lang racket

;; human player via command-line

(module+ test (require rackunit))
(provide lui-player%
         run-local-lui-game)

(require "./referee.rkt"
         "./player.rkt"
         "./tic-tac-toe.rkt")

(define lui-player%
  (class* object% (player<%>)
    (super-new)
    (define/public (get-move gam)
      (newline)
      (display-game gam)
      (begin0 (read-move)
        (displayln "waiting for opponent")))
    (define/public (notify-end gam)
      (newline)
      (display-game-end gam))))

(define numpad-positions
  (list (position 2 0) (position 2 1) (position 2 2)
        (position 1 0) (position 1 1) (position 1 2)
        (position 0 0) (position 0 1) (position 0 2)))

; a NumpadNumber is an integer between 1 and 9 inclusive

; NumpadNumber -> Position
(define (numpad->position n)
  (list-ref numpad-positions (sub1 n)))

; Position -> NumpadNumber
(define (position->numpad pos)
  (add1 (index-of numpad-positions pos)))

(module+ test
  (check-equal? (numpad->position 7)
                (position 0 0))
  (check-equal? (position->numpad (position 2 2))
                3))

; Game -> Void
(define (display-game gam [display-turn? #t])
  (when display-turn?
    (displayln (format "it is ~a's turn" (game-next-player gam))))
  (displayln (game->string gam)))

(define (game->string gam)
  (string-join (for/list ([row '(0 1 2)])
                 (apply format
                        " ~a │ ~a │ ~a "
                         (for/list ([col '(0 1 2)])
                           (define cell (game-get-cell gam (position row col)))
                           (or cell (position->numpad (position row col))))))
               "\n───┼───┼───\n"))

(define (display-game-end gam)
  (define winner (game-get-winner gam))
  (displayln
   (if winner
       (format "~a won!" winner)
       "draw"))
  (display-game gam #f))

; -> Move
(define (read-move)
  (display "enter the number of the space to make a move: ")
  (define move-datum (read))
  (match move-datum
    [(and n (? (lambda (v) (and (natural? v) (<= 1 v 9)))))
     (numpad->position n)]
    [_
     (displayln "invalid move, try again")
     (read-move)]))

(define (run-local-lui-game)
  (define lui-player (new lui-player%))
  (define lui-player-2 (new lui-player%))
  (define referee (new referee%))
  (call-with-values
   (lambda () (send referee play-game (list lui-player lui-player-2)))
   void))

(module+ main
  (run-local-lui-game))

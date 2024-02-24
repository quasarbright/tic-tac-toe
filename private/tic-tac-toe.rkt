#lang racket

;; game model

(module+ test (require rackunit))
(provide
 (struct-out game)
 (struct-out position)
 X
 O
 X_GO
 O_GO
 DRAW
 X_WIN
 O_WIN
 INITIAL-GAME
 position-valid?
 (contract-out
  [game-done? (-> game? any/c)]
  [game-get-cell (-> game? position? cell?)]
  [game-make-move (-> game? move? (or/c #f game?))]
  [game-move-is-legal? (-> game? move? any/c)]
  [game-status (-> game? game-status/c)]
  [game-get-winner (-> game? (or/c #f player-name?))]))

; A Game is a
(struct game [grid next-player] #:transparent)
; where
; grid is a 3x3 list of Cell. It is a list of rows.
; next-player is a PlayerName

; A Cell is a PlayerName or #f
; represents who has played in a space.
; #f represents an empty space.
(define (cell? v) (or (equal? #f v) (player-name? v)))

; A PlayerName is one of
(define X 'X)
(define O 'O)
(define (player-name? v) (or (equal? v X) (equal? v O)))

; a Move is a Position
; A Position is a
(struct position [row col] #:transparent)
; where row and col are 0, 1, or 2
; (position 0 0) is top-left
(define move? position?)


; A GameStatus is one of
; x's turn
(define X_GO 'X_GO)
; o's turn
(define O_GO 'O_GO)
; draw (terminal)
(define DRAW 'DRAW)
; x won (terminal)
(define X_WIN 'X_WIN)
; o wins (terminal)
(define O_WIN 'O_WIN)
(define game-status/c (or/c X_GO O_GO DRAW X_WIN O_WIN))

(define INITIAL-GAME
  (game '((#f #f #f)
          (#f #f #f)
          (#f #f #f))
        X))

; Game Move -> (or/c Game #f)
; make the move. if it is illegal, return #f
(define (game-make-move game move)
  (and (game-move-is-legal? game move)
       (game-make-move-unsafe game move)))

; Game Move -> Boolean
; is the move legal?
(define (game-move-is-legal? game move)
  (and (position-valid? move)
       (not (game-get-cell game move))))

; Position -> Boolean
; Is the position valid for a 3x3 grid?
(define (position-valid? pos)
  (and (position? pos)
       (<= 0 (position-row pos) 2)
       (<= 0 (position-col pos) 2)))

; Game Position -> Cell
; Get the cell at the specified position
(define (game-get-cell game pos)
  (list-ref (list-ref (game-grid game) (position-row pos))
            (position-col pos)))

(define (game-make-move-unsafe game move)
  (game-toggle-next-player (game-set-cell game move (game-next-player game))))

; Game -> Game
; Toggle the next player between X and O
(define (game-toggle-next-player gam)
  (match gam
    [(game grid next-player)
     (game grid (if (equal? next-player X) O X))]))

; Game Position Cell -> Game
; Set the value of the cell at the given position
(define (game-set-cell gam pos cell)
  (match gam
    [(game grid next-player)
     (define row-cells (list-ref grid (position-row pos)))
     (define row-cells^ (list-set row-cells (position-col pos) cell))
     (game (list-set grid (position-row pos) row-cells^) next-player)]))

; Game -> GameStatus
; Get the status of the game.
(define (game-status gam)
  (if (game-done? gam)
      (match (game-get-winner gam)
        [#f DRAW]
        [(== X) X_WIN]
        [(== O) O_WIN])
      (if (equal? X (game-next-player gam))
          X_GO
          O_GO)))

; Game -> Boolean
; Is the game done? It is done when there are no empty spaces.
(define (game-done? gam)
  (or (game-get-winner gam)
      (for*/and ([row (game-grid gam)]
                 [cell row])
        cell)))

(module+ test
  (check-not-false (game-done? (game '((X #f #f)
                                       (#f X #f)
                                       (#f #f X))
                                     O))))

; Game -> (or/c Player #f)
; get the winner, or #f if there is none.
(define (game-get-winner gam)
  (define coords '(0 1 2))
  (define lines
    (append
     ; columns
     (for/list ([col coords])
       (for/list ([row coords]) (position row col)))
     ; rows
     (for/list ([row coords])
       (for/list ([col coords]) (position row col)))
     ; down-right diagonal
     (list (for/list ([coord coords]) (position coord coord)))
     ; up-right diagonal
     (list (for/list ([coord coords]) (position coord (- 2 coord))))))
  (for/or ([line lines])
    (define cells (for/list ([pos line])
                    (game-get-cell gam pos)))
    (and (for/and ([cell cells]) cell)
         (for/and ([cell1 cells]
                   [cell2 (rest cells)])
           (equal? cell1 cell2))
         (first cells))))

(module+ test
  (check-equal? (game-get-winner INITIAL-GAME) #f)
  (check-equal? (game-get-winner (game '((#f X O)
                                         (#f X O)
                                         (#f X #f))
                                       O))
                X)
  (check-equal? (game-get-winner (game '((#f O X)
                                         (#f O X)
                                         (#f O #f))
                                       X))
                O)
  (check-equal? (game-get-winner (game '((#f #f #f)
                                         (O  O  O)
                                         (#f X  X))
                                       X))
                O)
  (check-equal? (game-get-winner (game '((O  #f #f)
                                         (#f O  #f)
                                         (X  X  O))
                                       X))
                O)
  (check-equal? (game-get-winner (game '((#f #f O)
                                         (#f O  #f)
                                         (O  X  X))
                                       X))
                O)
  (check-equal? (game-get-winner (game '((X O X)
                                         (X O O)
                                         (O X X))
                                       O))
                #f))

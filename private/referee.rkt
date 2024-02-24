#lang racket

(module+ test (require rackunit))
(provide referee<%>
         referee%
         naive-player%)

(require racket/sandbox
         "./player.rkt"
         "./tic-tac-toe.rkt")

(define MOVE_TIME_LIMIT_SECS 60)
(define MOVE_MEMORY_LIMIT_MB 1000)

(define referee<%>
  (interface ()
    ; Game (listof Player) -> (values Game (listof Player))
    ; Play the game with the list of players.
    ; Return the final game state and the list of players that were kicked.
    play-game))

(define referee%
  (class* object% (referee<%>)
    (super-new)
    (define/public (play-game gam players)
      (apply values
             (let/ec abort
               (let loop ([gam gam] [players players])
                 (when (game-done? gam)
                   (abort (list gam '())))
                 (define next-player (first players))
                 (define players^ (append (rest players) (list next-player)))

                 (define move (with-protection (send next-player get-move gam)))
                 (unless move
                   ; player failed to supply a move
                   (abort (list gam (list next-player))))

                 (define gam^ (game-make-move gam move))
                 (unless gam^
                   ; move was illegal
                   (abort (list gam (list next-player))))

                 (loop gam^ players^)))))))

; always plays top-left
(define top-left-player%
  (class* object% (player<%>)
    (super-new)
    (define/public (get-move _) (position 0 0))
    (define/public (notify-end _) (void))))
(define top-left-player (new top-left-player%))

; plays the first legal move it finds, searching in reading order, or top-left if none are legal.
(define naive-player%
  (class* object% (player<%>)
    (super-new)
    (define/public (get-move gam)
      (or (for*/first ([row '(0 1 2)]
                       [col '(0 1 2)]
                       #:when (game-move-is-legal? gam (position row col)))
            (position row col))
          (position 0 0)))
    (define/public (notify-end _) (void))))
(define naive-player (new naive-player%))

(define player-with-strategy%
  (class* object% (player<%>)
    (super-new)
    (init-field strategy)
    (define/public (get-move gam)
      (strategy gam))
    (define/public (notify-end _) (void))))
(define (player-with-strategy strategy) (new player-with-strategy% [strategy strategy]))

(define broken-player (player-with-strategy (lambda (_) (error "I couldn't think of a move"))))

(define-syntax-rule (with-protection body ...)
  (with-handlers ([exn:fail? (lambda (_) #f)])
    (with-limits MOVE_TIME_LIMIT_SECS MOVE_MEMORY_LIMIT_MB
      body ...)))

(module+ test
  (define ref (new referee%))
  (define second-top-left-player (new top-left-player%))
  (let-values ([(gam^ kicked-players) (send ref play-game INITIAL-GAME (list top-left-player second-top-left-player))])
    (check-equal? gam^
                  (game '((X  #f #f)
                          (#f #f #f)
                          (#f #f #f))
                        O))
    (check-equal? kicked-players (list second-top-left-player)))
  (let-values ([(gam^ kicked-players) (send ref play-game INITIAL-GAME (list top-left-player broken-player))])
    (check-equal? gam^
                  (game '((X  #f #f)
                          (#f #f #f)
                          (#f #f #f))
                        O))
    (check-equal? kicked-players (list broken-player)))
  (let-values ([(gam^ kicked-players) (send ref play-game INITIAL-GAME (list naive-player naive-player))])
    (check-equal? gam^
                  (game '((X O X)
                          (O X O)
                          (X O X))
                        O))
    (check-equal? kicked-players '())))

#lang racket

(require racket/gui/easy
         racket/gui/easy/operator
         "./player.rkt"
         "./tic-tac-toe.rkt")

(define gui-player%
  (class* object% (player<%>)
    (super-new)
    (define @gam (@ #f))
    (define move #f)
    (define @your-turn? (@ #f))
    (obs-observe! @gam (lambda (gam) (displayln gam)))
    (define (render-game gam your-turn?)
      (if gam
          (apply vpanel
                 (text (if your-turn?
                           "your turn"
                           "waiting for opponent"))
                 (for/list ([row '(0 1 2)])
                   (apply hpanel
                          (for/list ([col '(0 1 2)])
                            (define pos (position row col))
                            (define cell (game-get-cell gam pos))
                            (button (symbol->string (or cell (game-next-player gam)))
                                    (lambda () (set! move pos))
                                    #:enabled? (and your-turn? (not cell)))))))
          (text "waiting for game to start")))
    (thread (lambda ()
              (render
               (window
                #:title "Tic Tac Toe"
                #:size '(400 400)
                (observable-view
                 (obs-combine (lambda (gam your-turn?) (render-game gam your-turn?))
                              @gam
                              @your-turn?)
                 values)

                (text "tic tac toe")))))

    (define/public (get-move gam)
      (obs-set! @gam gam)
      (obs-set! @your-turn? #t)
      (sleep 1)
      (position 0 0)
      #;
      (touch (future
              (let loop ()
                (cond
                  [move (begin0 move (set! move #f) (obs-set! @your-turn? #f))]
                  [else (loop)])))))
    (define/public (notify-end _) (void))))

(module+ main
  (require "./referee.rkt")
  (define gui-player (new gui-player%))
  (define naive-player (new naive-player%))
  (define referee (new referee%))
  (send referee play-game INITIAL-GAME (list gui-player naive-player)))

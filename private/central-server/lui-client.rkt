#lang racket

(provide lui-client%)
(require "./client.rkt")

(define lui-client%
  (class* object% (client<%>)
    (super-new)
    (init-field
     ; -> Player
     make-player
     ; Server
     server)

    (define thd
      (thread
       (lambda ()
         (let loop ()
           (displayln "1: create a lobby")
           (displayln "2: join a lobby")
           (displayln "q: quit")
           (newline)
           (display "tic-tac-toe> ")
           (match (read)
             [1 (create-lobby) (loop)]
             [2 (join-lobby) (loop)]
             ['q (displayln "goodbye!")]
             [_ (displayln "invalid input. please enter 1, 2, or q")
                (loop)])))))

    (define (create-lobby)
      (define lobby (send server create-lobby! this))
      (displayln "lobby created")
      (in-lobby/host lobby))

    (define (in-lobby/host lobby)
      (displayln "you are the host of a lobby")
      (displayln (format "lobby id: ~a" (send lobby get-id)))
      (displayln "1: start game")
      (displayln "2: leave lobby")
      (match read
        ; TODO block until game ends
        [1 (send lobby start-game! this)]
        [2 (send lobby remove-client! this)]))

    (define (join-lobby)
      (displayln "enter lobby id: ")
      (define lobby-id (read-line))
      (match lobby-id
        ["q" (displayln "returning to main menu")]
        [_
         (define lobby (send server get-lobby this lobby-id))
         (cond
           [lobby
            (send lobby add-client! this)
            (in-lobby/joiner lobby)]
           [else
            (displayln "unable to join lobby, try again or enter 'q' to quit")
            (join-lobby)])]))

    (define (in-lobby/joiner lobby)
      'todo)

    (define/public (get-name)
      (displayln "enter your username: ")
      (read-line))
    (define/public (get-player) (make-player))))

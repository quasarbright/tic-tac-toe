#lang racket

;; Host a game server, allowing another player to remotely join.
;; Runs a command line player on this computer

(provide host-game)
(require nat-traversal
         "./server.rkt"
         "./referee.rkt"
         "./lui-player.rkt"
         "./tic-tac-toe.rkt"
         "./join-code.rkt"
         "./ngrok.rkt")

; -> Void
; host a game from this computer, allowing another player to remotely join.
(define (host-game)
  (displayln "launching server")
  (define server (new tcp-server%))
  (define private-port-no (send server get-port-no))
  (define-values
    (public-address public-port-no)
    (launch-ngrok-server private-port-no))
  (displayln (format "public server running at ~a:~a and this machine's port ~a"
                     public-address
                     public-port-no
                     private-port-no))
  (define join-code (make-join-code public-address public-port-no))
  (displayln (format "join code: ~a" join-code))
  (displayln "waiting for another player to join")
  (define remote-player (send server signup))
  (displayln "player joined, starting game")

  (define human-player (new lui-player%))
  (define referee (new referee%))
  (send referee play-game (list human-player remote-player))
  (send server close))

; -> string?
; get this computer's IP address
(define (get-ip-address)
  ; this is necessary because best-interface-ip-address doesn't work on windows
  (if (eq? 'windows (system-type 'os))
      (get-ip-address/windows)
      (best-interface-ip-address)))

; -> string?
; get this computer's IP address, only for windows
(define (get-ip-address/windows)
  (define output
    (with-output-to-string
      (lambda ()
        (system "ipconfig | findstr /i \"ipv4\""))))
  (define addresses (regexp-match* #px"(\\d+\\.)+\\d+" output))
  (when (null? addresses)
    (error 'get-ip-address "unable to find ip address"))
  (first addresses))

(module+ main
  (host-game))

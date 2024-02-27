#lang racket

;; this is currently just for design, not yet for implementation

; trying to think of what implementation component makes sense
; maybe you should have a LobbyManager
(define lobby-manager<%>
  (interface ()
    ; LobbyMember -> Void
    add-member!

    ; LobbyMember -> Void
    remove-member!

    ; Void
    play-game))

(define lobby-member<%>
  (interface ()
    ; -> Player
    get-player

    ; -> Void
    notify-remove))







; A PublicUserInfo is a
(struct public-user-info [name] #:transparent)
; where name is a string

; A LobbyId is a string identifying a lobby

; A PublicLobbyInfo is a
(struct public-lobby-info [id users])

(define central-game-client<%>
  (interface ()
    ; -> Player
    get-player))

(define central-game-server<%>
  (interface ()
    ; (LobbyInfo -> Void) -> LobbyInfo
    ; (create-lobby on-change) ->
    create-lobby))

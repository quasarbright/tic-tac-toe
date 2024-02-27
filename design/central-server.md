# Central Game Server Design

This document contains the initial design notes for the central game server model.

At the time of writing this, the networking currently works like this:
1. Alice wants to host a game and Bob wants to join Alice's game
1. Alice hosts a game, which launches a local tcp server and a public ngrok tcp server, which proxies the local one.
1. Alice sees a join code, which contains the address and port of the public tcp server.
1. Alice sends bob the join code
1. Bob connects to the server using the join code
1. The game begins
1. Alice's moves are communicated directly to the server on the same machine, Bob's moves come in through tcp, with ngrok as the middle man, proxying Alice's local server.
1. The game ends, connections are terminated and the server shuts down (both local and ngrok)

This has a few disadvantages:
* to host, ngrok must be installed on the host's computer
* a malicious host can cheat since they are in complete control of the game

A central game server would solve these problems.

Here is an example sequence to show how this works at a high level:

```
Assume central game server is running

# connect
Alice -> CGS: connect
Bob -> CGS: connect

# lobby
Alice -> CGS: create (private) lobby
Alice <- CGS: lobby info
Alice ~> Bob: lobby info (sent outside of system)
Bob -> CGS: join alice's lobby
Bob <- CGS: void
CGS -> Alice: player joined
CGS <- Alice: void
Alice -> CGS: start game
Alice <- CGS: void

# gameplay
loop until game ends:
  CGS -> Alice: (get-move gam)
  CGS <- Alice: mov
  CGS -> Bob: (get-move gam)
  Bob <- CGS: mov
CGS -> Alice: (notify-end gam)
CGS <- Alice: void
CGS -> Bob: (notify-end gam)
CGS <- Bob: void

# disconnect
Alice -> CGS: disconnect
Bob -> CGS: disconnect
```



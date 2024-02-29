# Central Game Server Design

This document contains the initial design notes for the central game server model.

At the time of writing this, the networking currently works like this:
1. Alice wants to host a game and Bob wants to join Alice's game
1. Alice hosts a game, which launches a local tcp server and a public ngrok tcp server, which proxies the local one.
1. Alice sees a join code, which contains the address and port of the public tcp server.
1. Alice sends bob the join code outside of this system
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

server is going to be one process, but it needs to handle concurrent games, lobbies, etc. how should this work?

central loop:
  accept connection
  in a new thread for that client:
    wait for them to create or join a lobby
    if they create a lobby:
      in a new thread for that lobby:
        wait for players to join/leave, or for host to start the game
        when start game, create proxy players and run referee.
        when host leaves/disconnects, shut down lobby.
    if they join a lobby:
      find the lobby, add them to it. this means there needs to be a global mutable lobby store. fantastic.

maybe use actors! esp with a global lobby store.
but actors don't work very well with request and response. could try to make an extension of actors that does though.

i wonder how racket handles concurrent method calls. i'd be worried about concurrent list mutations, but other stuff should be fine.

need some way of propagating disconnects?

data model for server side:
server:
  clients: listof client
  lobbies: listof lobby
  
  // methods for client
  create-lobby(host: client) => lobby
  get-lobby(id: string) => lobby

client:
  // proxy client fields
  id: string
  name: string
  input and output port
  thread: thread
  lobby: lobby or #f (if not in one)
  server: server
  
  // methods for lobby
  get-name() => string
  get-player() => player
  // maybe just notify on lobby change and send public lobby info
  notify-client-joined-lobby(username: string) => void
  notify-client-left-lobby(username: string) => void
  notify-game-starting() => void
  notify-game-end() => void
  // notifying a client that they have been disconnected
  notify-disconnect-from-lobby() => void

lobby:
  id: string
  clients: listof client
  host: client
  thread: thread
  server: server
  referee: referee
  
  // methods for (proxy) client
  // start a game in the lobby. only host can do this, 
  // so client sends itself to prove it's the host.
  start-game(client: client) => void
  // client will add itself. returns usernames in lobby. maybe just return public lobby info
  add-client(client: client) => (listof string?)
  // client will remove itself
  remove-client(client: client) => void

server will only have proxy clients. when they receive a command from the real client
to start a game or something, proxy servers will send themselves.

here is the above sequence in terms of these methods:

```
A -> B is method call on the server computer
A ~> B is remote communication
A ~~> B is outside of the system

# connect

server is created and starts accepting connections

Alice ~> CGS: connect
server creates alice-client, a proxy client
alice-client gets its own thread that listens to alice's tcp input
Alice ~> alice-client: my name is "Alice"

Bob ~> CGS: connect
server creates bob-client, a proxy client
bob-client gets its own thread that listens to bob's tcp input
Bob ~> bob-client: my name is "Bob"

# lobby

Alice ~> alice-proxy: create lobby
alice-client -> CGS: (create-lobby alice-client)
alice-client <- CGS: alice-lobby
Alice <~ alice-proxy: alice-lobby-id

Alice ~~> Bob: alice-lobby-id

Bob ~> bob-client: join lobby alice-lobby-id
bob-client -> CGS: (get-lobby alice-lobby-id)
bob-client <- CGS: alice-lobby
bob-client -> alice-lobby: (add-client bob-client)
bob-client <- alice-lobby: (list "Alice" "Bob")
Bob <~ bob-client: (list "Alice" "Bob")
alice-lobby -> alice-client: (notify-client-joined-lobby "Bob")
alice-client ~> Alice: "Bob" has joined the lobby
alice-client <~ Alice: void
alice-lobby <- alice: void

Alice ~> alice-client: start the game
alice-client -> alice-lobby: (start-game alice-client)
alice-client <- alice-lobby: void
Alice <~ alice-client: void

# game setup

alice-lobby -> alice-client: (notify-game-starting)
alice-client ~> Alice: game is starting
alice-client <~ Alice: void
alice-lobby <- alice-client: void

same thing but notifying bob

alice-lobby -> alice-client: (get-player)
alice-lobby <- alice-client: alice-player

same thing but getting bob's player bob-player

alice-lobby has alice-referee

# game

alice-lobby -> alice-referee: (play-game INITIAL-GAME (list alice-player bob-player))

standard interactions between alice-referee, alice-player, bob-player, Alice, and Bob for a game

# game cleanup

alice-lobby -> alice-client: (notify-game-end)
alice-client ~> Alice: game ended
alice-client <~ Alice: void
alice-lobby <- alice-client: void

same with bob

# disconnect

Alice ~> alice-client: leave lobby
alice-client -> alice-lobby: (remove-client alice-client)
alice-client <- alice-lobby: void
Alice <~ alice-client: void

alice-lobby -> bob-client: (notify-disconnect-from-lobby)
bob-client ~> Bob: you have disconnected from the lobby
bob-client <~ Bob: void
alice-lobby <- bob-client: void
```

notice that there is not a one-to-one correspondence between method calls on clients and remote communications. For example, when a user wants to join a lobby, the client fetches the lobby from the server, and then adds itself to the lobby.

some other complications:
* previously, the server drove all communication and clients were send requests and responded. when the client screwed up, we'd just kick them. but now, clients can send requests to the server/lobby. so if someone tries to join a lobby and the lobby is full or something, we have to send an error response back to the client or something like that. should have some standard protocol, like responses have a status and either a body or an error message.


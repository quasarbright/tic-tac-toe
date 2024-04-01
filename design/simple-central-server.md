# Simple Central Server Design

It's pretty much the same thing as the peer-to-peer ngrok stuff, but there is a central server in between.

example interaction:

Alice hosts, Bob joins

```
Alice connects to server
Bob connects to server

Alice -> Server: (host-game)
Alice <- Server: join-code

Alice -> Bob: join-code ; (sent outside of the system)

Bob -> Server: (join-game join-code)
Bob <- Server: true

game is played

Alice and Bob are disconnected from server
```

For the joiner, it's almost identical to the peer-to-peer. For the host, rather than running the server, they connect to the server, request to host, and receive a join code to send to their friend.

The join code will now be a UUID instead of an IP address and port. No need to include that information since they'll already be connected to the server by the time they are sending/using join codes.

No need for a client interface on the server side. After connection, the server will receive either host-game or join-game, run a game, and then disconnect the clients.

Server will store connections and a mapping from join codes to pending games. Need atomics.

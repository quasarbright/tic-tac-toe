tic-tac-toe
===========
online tic tac toe

System requirements:
* If you want to host a peer-to-peer game directly from your computer, you must have [`ngrok`](https://ngrok.com) installed and configured.

Install:

TODO make release and link to it

## Building from source

Requirements:

* [Racket](https://racket-lang.org/). tested on version 8.9 and 8.7
* `raco` pacakge manager (comes with Racket)

First, clone the repository

Then install the package by navigating to the repository root and running

``` sh
raco pkg install
```

You can run the program with

``` sh
racket main.rkt
```

To create an executable, navigate to the repository root and run

``` sh
raco exe --ico icons/icon.ico --icns icons/icon.icns --embed-dlls -o exe/tic-tac-toe main.rkt
raco distribute dist exe/*
```

This will create an executable in the `dist/` directory. On windows, it will be a standalone exe file. On macos, it will be a `bin/` directory with the executable inside, and a `lib/` directory containing the libraries needed to run the executable.


## Running the central server

run playit.gg.

navigate to the repository root and run

``` sh
cd private/simple-game-server
racket server.rkt
```

The public hostname and port number are currently hard-coded in `private/simple-game-server/lui-menu.rkt`.

The private port number is hard-coded in `private/simple-game-server/server.rkt`.

You can view your playit.gg the tunnels here: https://playit.gg/account/tunnels

If you're not me and you want to get your own central server working, you'll have to change the hard-coded public hostname and port number to those in your playit.gg.

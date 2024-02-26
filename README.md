tic-tac-toe
===========
online tic tac toe

## Building from source

Requirements:

* [Racket](https://racket-lang.org/). tested on version 8.9
* `raco` pacakge manager (comes with Racket)

First, clone the repository

Then install the package by navigating to the repository root and running

``` sh
raco pkg install
```

To create an executable,

On windows:

``` sh
raco exe --ico icons/icon.ico -o tic-tac-toe.exe main.rkt
```

This will create `tic-tac-toe.exe` at the repository root.


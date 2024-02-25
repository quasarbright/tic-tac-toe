#lang info
(define collection "tic-tac-toe")
(define deps '("base" "gui-easy" "nat-traversal" "sandbox-lib"))
(define build-deps '("scribble-lib" "racket-doc" "rackunit-lib"))
(define scribblings '(("scribblings/tic-tac-toe.scrbl" ())))
(define pkg-desc "Online tic tac toe")
(define version "0.0")
(define pkg-authors '("Mike Delmonaco"))
(define license '(Apache-2.0 OR MIT))

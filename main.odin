package main

import "core:fmt"

main :: proc() {
  term, _ := parse(`(\x. \y. y) a b`)  // aka: snd a b
  if reduced, ok := reduce(term); ok {
    fmt.println(term_to_string(reduced))  // prints b
  }
}

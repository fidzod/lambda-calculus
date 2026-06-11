package main

import "core:fmt"

main :: proc() {
  tokens, ok := tokenise("(\\x. x) x")
  if ok {
    for tok in tokens {
      fmt.println(tok)
    }
    delete(tokens)
  }
}

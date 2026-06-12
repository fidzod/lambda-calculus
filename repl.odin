package main

import "core:fmt"
import "core:os"
import "core:strings"

repl :: proc() {
  buf: [256]byte
  fmt.print("λ> ")
  for {
    n, err := os.read(os.stdin, buf[:])
    if err != nil do break
    input := strings.trim_right(string(buf[:n]), "\n\r")
    if input == "quit" do break
    term, ok := parse(input)
    if !ok {
      fmt.print("λ> ")
      continue
    }
    reduced, ok2 := reduce(term)
    if !ok2 {
      fmt.println("No normal form found (max steps exceeded)")
    } else {
      fmt.println(term_to_string(reduced))
    }
    fmt.print("λ> ")
  }
}

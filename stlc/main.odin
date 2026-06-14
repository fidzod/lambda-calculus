package main

import "core:fmt"

main :: proc() {
  ctx := make(map[string]^Type)
  if ast, ok := parse(`(\f:i->i. \x:i. x) (\x:i. x)`); ok {
    if t, ok := typecheck(ctx, ast); ok {
      fmt.println(type_to_string(t))
    } else {
      fmt.println("type error")
    }
  }
}

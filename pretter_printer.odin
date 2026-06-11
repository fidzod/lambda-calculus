package main

import "core:fmt"

term_to_string :: proc(term: ^Term) -> string {
  if var, ok := term.(Var); ok {
    return var.name
  }
  else if abs, ok := term.(Abs); ok {
    return fmt.tprintf("(λ%s. %s)", abs.param, term_to_string(abs.body))
  }
  else if app, ok := term.(App); ok {
    return fmt.tprintf("(%s %s)", term_to_string(app.rator), term_to_string(app.rand))
  }
  unreachable()
}

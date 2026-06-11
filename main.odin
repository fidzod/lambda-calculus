package main

import "core:fmt"

Term :: union {
  Var,
  Abs,
  App,
}

Var :: struct {
  name: string,
}

Abs :: struct {
  param: string,
  body: ^Term,
}

App :: struct {
  rator: ^Term,
  rand: ^Term,
}

main :: proc() {
  // x
  x1 := new(Term)
  defer free(x1)
  x1^ = Var{name = "x"}

  // \x.x 
  abs := new(Term)
  defer free(abs)
  abs^ = Abs{ param = "x", body = x1 }

  // x
  x2 := new(Term)
  defer free(x2)
  x2^ = Var{name = "x"}

  // (\x. x) x
  app := new(Term)
  defer free(app)
  app^ = App{rator = abs, rand = x2}

  fmt.println(term_to_string(app))  // ((λx. x) x)
}

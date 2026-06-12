package main

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

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
  param_type: ^Type,
  body: ^Term,
}

App :: struct {
  rator: ^Term,
  rand: ^Term,
}

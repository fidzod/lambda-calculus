package main

reduce_step :: proc(term: ^Term) -> (^Term, bool) {
  if var, ok := term.(Var); ok {
    return nil, false
  }
  if abs, ok := term.(Abs); ok {
    if body_reduced, ok := reduce_step(abs.body); ok {
      res := new(Term)
      res^ = Abs{ abs.param, body_reduced }
      return res, true
    }
    return nil, false
  }
  if app, ok := term.(App); ok {
    if abs, ok:= app.rator.(Abs); ok {
      return substitute(abs.param, app.rand, abs.body), true
    }
    else if rator_reduced, ok := reduce_step(app.rator); ok {
      res := new(Term)
      res^ = App{ rator_reduced, app.rand }
      return res, true
    }
    else if rand_reduced, ok := reduce_step(app.rand); ok {
      res := new(Term)
      res^ = App{ app.rator, rand_reduced }
      return res, true
    }
    else {
      return nil, false
    }
  }
  unreachable()
}

reduce :: proc(term: ^Term, max_steps := 1000) -> (^Term, bool) {
  current := term
  for i in 0..<max_steps {
    next, ok := reduce_step(current)
    if !ok do return current, true
    current = next
  }
  return nil, false
}

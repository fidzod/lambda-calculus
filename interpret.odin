package main

import "core:fmt"

fresh_counter := 0

alpha_convert :: proc(base: string) -> string {
  fresh_counter += 1
  return fmt.tprintf("%s%d", base, fresh_counter)
}

is_free :: proc(name: string, term: ^Term) -> bool {
  if var, ok := term.(Var); ok {
    // FV(x) = {x}
    return var.name == name
  }
  else if abs, ok := term.(Abs); ok {
    // FV(M₁ M₂) = FV(M₁) ⋃ FV(M₂)
    return is_free(name, abs.body) && name != abs.param
  }
  else if app, ok := term.(App); ok {
    // FV(λx.M) = FV(M)\{x}
    return is_free(name, app.rand) || is_free(name, app.rator)
  }
  unreachable()
}

substitute :: proc(name: string, replacement: ^Term, term: ^Term) -> ^Term {
  if var, ok := term.(Var); ok {
    return var.name == name ? replacement : term
  }
  else if abs, ok := term.(Abs); ok {
    if abs.param == name {
      res := new(Term)
      res^ = Abs{ abs.param, abs.body }
      return res
    }
    else if is_free(abs.param, replacement) {
      fresh_name := alpha_convert(abs.param)
      fresh_var := new(Term)
      fresh_var^ = Var{ fresh_name }

      res := new(Term)
      res^ = Abs{
        fresh_name,
        substitute(name, replacement, substitute(abs.param, fresh_var, abs.body))
      }

      return res
    }
    else {
      res := new(Term)
      res^ = Abs{ abs.param, substitute(name, replacement, abs.body) }
      return res
    }
  }
  else if app, ok := term.(App); ok {
    res := new(Term)
    res^ = App{
      substitute(name, replacement, app.rator),
      substitute(name, replacement, app.rand)
    }
    return res;
  }
  unreachable()
}

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

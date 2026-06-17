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
	} else if abs, ok := term.(Abs); ok {
		// FV(λx.M) = FV(M)\{x}
		return is_free(name, abs.body) && name != abs.param
	} else if app, ok := term.(App); ok {
		// FV(M₁ M₂) = FV(M₁) ⋃ FV(M₂)
		return is_free(name, app.rand) || is_free(name, app.rator)
	}
  else if _, ok := term.(True); ok do return false
	else if _, ok := term.(False); ok do return false
	else if _, ok := term.(Zero); ok do return false
	else if succ, ok := term.(Succ); ok do return is_free(name, succ.body)
	else if pred, ok := term.(Pred); ok do return is_free(name, pred.body)
	else if iszero, ok := term.(Is_Zero); ok do return is_free(name, iszero.body)
	else if if_stmt, ok := term.(If); ok {
		return is_free(name, if_stmt.condition) ||
      is_free(name, if_stmt.consequent) ||
      is_free(name, if_stmt.alternate)
	} else if fix, ok := term.(Fix); ok do return is_free(name, fix.body)
	unreachable()
}

substitute :: proc(name: string, replacement: ^Term, term: ^Term) -> ^Term {
	if var, ok := term.(Var); ok {
		return var.name == name ? replacement : term
	} else if abs, ok := term.(Abs); ok {
		if abs.param == name {
			res := new(Term)
			res^ = Abs{abs.param, abs.param_type, abs.body}
			return res
		} else if is_free(abs.param, replacement) {
			fresh_name := alpha_convert(abs.param)
			fresh_var := new(Term)
			fresh_var^ = Var{fresh_name}

			res := new(Term)
			res^ = Abs {
				fresh_name,
				abs.param_type,
				substitute(name, replacement, substitute(abs.param, fresh_var, abs.body)),
			}

			return res
		} else {
			res := new(Term)
			res^ = Abs{abs.param, abs.param_type, substitute(name, replacement, abs.body)}
			return res
		}
	} else if app, ok := term.(App); ok {
		res := new(Term)
		res^ = App {
			substitute(name, replacement, app.rator),
			substitute(name, replacement, app.rand),
		}
		return res
	} else if _, ok := term.(True); ok do return term
	else if _, ok := term.(False); ok do return term
	else if _, ok := term.(Zero); ok do return term
	else if succ, ok := term.(Succ); ok {
		res := new(Term)
		res^ = Succ{substitute(name, replacement, succ.body)}
		return res
	} else if pred, ok := term.(Pred); ok {
		res := new(Term)
		res^ = Pred{substitute(name, replacement, pred.body)}
		return res
	} else if iszero, ok := term.(Is_Zero); ok {
		res := new(Term)
		res^ = Is_Zero{substitute(name, replacement, iszero.body)}
		return res
	} else if if_stmt, ok := term.(If); ok {
		res := new(Term)
		res^ = If {
			condition  = substitute(name, replacement, if_stmt.condition),
			consequent = substitute(name, replacement, if_stmt.consequent),
			alternate  = substitute(name, replacement, if_stmt.alternate),
		}
		return res
	} else if fix, ok := term.(Fix); ok {
		res := new(Term)
		res^ = Fix{substitute(name, replacement, fix.body)}
		return res
	}

	unreachable()
}

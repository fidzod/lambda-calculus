package main

reduce_step :: proc(term: ^Term) -> (^Term, bool) {
	if var, ok := term.(Var); ok {
		return nil, false
	}
	if abs, ok := term.(Abs); ok {
		/*
		if body_reduced, ok := reduce_step(abs.body); ok {
			res := new(Term)
			res^ = Abs{abs.param, abs.param_type, body_reduced}
			return res, true
		}
    */
		return nil, false
	}
	if app, ok := term.(App); ok {
		if fix, ok := app.rator.(Fix); ok {
			new_fix := new(Term)
			new_fix^ = Fix{fix.body}
			inner := new(Term)
			inner^ = App {
				rator = fix.body,
				rand  = new_fix,
			}
			result := new(Term)
			result^ = App {
				rator = inner,
				rand  = app.rand,
			}
			return result, true
		} else if abs, ok := app.rator.(Abs); ok {
			return substitute(abs.param, app.rand, abs.body), true
		} else if rator_reduced, ok := reduce_step(app.rator); ok {
			res := new(Term)
			res^ = App{rator_reduced, app.rand}
			return res, true
		} else if rand_reduced, ok := reduce_step(app.rand); ok {
			res := new(Term)
			res^ = App{app.rator, rand_reduced}
			return res, true
		} else {
			return nil, false
		}
	}

	if _, ok := term.(True); ok do return nil, false
	if _, ok := term.(False); ok do return nil, false
	if _, ok := term.(Zero); ok do return nil, false

	if succ, ok := term.(Succ); ok {
		if body_reduced, ok := reduce_step(succ.body); ok {
			res := new(Term)
			res^ = Succ{body_reduced}
			return res, true
		}
		return nil, false
	}

	if pred, ok := term.(Pred); ok {
		if _, body_is_zero := pred.body.(Zero); body_is_zero do return pred.body, true

		if succ, body_is_succ := pred.body.(Succ); body_is_succ do return succ.body, true

		if body_reduced, ok := reduce_step(pred.body); ok {
			res := new(Term)
			res^ = Pred{body_reduced}
			return res, true
		}
		return nil, false
	}

	if iszero, ok := term.(Is_Zero); ok {
		if _, body_is_zero := iszero.body.(Zero); body_is_zero {
			res := new(Term)
			res^ = True{}
			return res, true
		}
		if _, body_is_succ := iszero.body.(Succ); body_is_succ {
			res := new(Term)
			res^ = False{}
			return res, true
		}
		if body_reduced, ok := reduce_step(iszero.body); ok {
			res := new(Term)
			res^ = Is_Zero{body_reduced}
			return res, true
		}
		return nil, false
	}

	if if_statement, ok := term.(If); ok {
		if _, cond_is_true := if_statement.condition.(True); cond_is_true {
			return if_statement.consequent, true
		}
		if _, cond_is_false := if_statement.condition.(False); cond_is_false {
			return if_statement.alternate, true
		}
		if cond_reduced, ok := reduce_step(if_statement.condition); ok {
			res := new(Term)
			res^ = If {
				condition  = cond_reduced,
				consequent = if_statement.consequent,
				alternate  = if_statement.alternate,
			}
			return res, true
		}
		return nil, false
	}

	if fix, ok := term.(Fix); ok {
		return nil, false
	}

	unreachable()
}

reduce :: proc(term: ^Term, max_steps := 1000000) -> (^Term, bool) {
	current := term
	for i in 0 ..< max_steps {
		next, ok := reduce_step(current)
		if !ok do return current, true
		current = next
	}
	return nil, false
}

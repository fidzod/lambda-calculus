package main

import "core:fmt"

type_to_string :: proc(type: ^Type) -> string {
	if b, ok := type.(TypeBase); ok do return b.name
	a, _ := type.(TypeArrow)
	return fmt.tprintf("(%s->%s)", type_to_string(a.domain), type_to_string(a.codomain))
}

nat_value :: proc(term: ^Term, counter: int = 0) -> (int, bool) {
	if _, is_zero := term.(Zero); is_zero do return counter, true
	succ, is_succ := term.(Succ)
	if !is_succ do return 0, false
	return nat_value(succ.body, counter + 1)
}

term_to_string :: proc(term: ^Term) -> string {
	if var, ok := term.(Var); ok {
		return var.name
	} else if abs, ok := term.(Abs); ok {
		return fmt.tprintf(
			"(λ%s:%s. %s)",
			abs.param,
			type_to_string(abs.param_type),
			term_to_string(abs.body),
		)
	} else if app, ok := term.(App); ok {
		return fmt.tprintf("(%s %s)", term_to_string(app.rator), term_to_string(app.rand))
	} else if _, ok := term.(True); ok {
		return "true"
	} else if _, ok := term.(False); ok {
		return "false"
	} else if _, ok := term.(Zero); ok {
		return "0"
	} else if succ, ok := term.(Succ); ok {
    if nat, ok := nat_value(term); ok do return fmt.tprintf("[=%d]", nat)
		return fmt.tprintf("(succ %s)", term_to_string(succ.body))
	} else if pred, ok := term.(Pred); ok {
		return fmt.tprintf("(pred %s)", term_to_string(pred.body))
	} else if iszero, ok := term.(Is_Zero); ok {
		return fmt.tprintf("(is_zero %s)", term_to_string(iszero.body))
	} else if if_statement, ok := term.(If); ok {
		return fmt.tprintf(
			"(if (%s) then (%s) else (%s))",
			term_to_string(if_statement.condition),
			term_to_string(if_statement.consequent),
			term_to_string(if_statement.alternate),
		)
	} else if fix, ok := term.(Fix); ok {
		return fmt.tprintf("(fix %s)", term_to_string(fix.body))
	}
	unreachable()
}

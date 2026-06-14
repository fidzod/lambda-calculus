package main

import "core:fmt"

type_to_string :: proc(type: ^Type) -> string {
	if b, ok := type.(TypeBase); ok do return b.name
	a, _ := type.(TypeArrow)
	return fmt.tprintf("%s->%s", type_to_string(a.domain), type_to_string(a.codomain))
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
	}
	unreachable()
}

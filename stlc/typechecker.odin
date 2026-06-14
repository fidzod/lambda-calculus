package main

are_same_type :: proc(t1: ^Type, t2: ^Type) -> bool {
	t1a, t1_is_arrow := t1.(TypeArrow)
	t1b, t1_is_base := t1.(TypeBase)
	t2a, t2_is_arrow := t2.(TypeArrow)
	t2b, t2_is_base := t2.(TypeBase)

	if t1_is_base && t2_is_base {
		return t1b.name == t2b.name
	} else if t1_is_arrow && t2_is_arrow {
		return are_same_type(t1a.domain, t2a.domain) && are_same_type(t1a.codomain, t2a.codomain)
	}

	return false
}

typecheck :: proc(ctx: map[string]^Type, term: ^Term) -> (^Type, bool) {
	if var, ok := term.(Var); ok {
		if t, ok := ctx[var.name]; ok do return t, true
		return nil, false
	} else if abs, ok := term.(Abs); ok {
		abs_ctx := make(map[string]^Type)
		for key, value in ctx do abs_ctx[key] = value
		abs_ctx[abs.param] = abs.param_type

		arrow := new(Type)
		codomain, ok := typecheck(abs_ctx, abs.body)
		if !ok do return nil, false

		arrow^ = TypeArrow {
			domain   = abs.param_type,
			codomain = codomain,
		}
		return arrow, true
	} else if app, ok := term.(App); ok {
		f, ok1 := typecheck(ctx, app.rator)
		if !ok1 do return nil, false

		f_arrow, ok2 := f.(TypeArrow)
		if !ok2 do return nil, false

		a, ok3 := typecheck(ctx, app.rand)
		if !ok3 do return nil, false

		if !are_same_type(a, f_arrow.domain) do return nil, false
		return f_arrow.codomain, true
	}
	unreachable()
}

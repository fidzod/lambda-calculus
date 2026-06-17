package main

base :: proc(name: string) -> ^Type {
  base_type := new(Type)
  base_type^ = TypeBase{ name = name }
  return base_type
}

arrow :: proc(domain: ^Type, codomain: ^Type) -> ^Type {
  arrow_type := new(Type)
  arrow_type^ = TypeArrow{ domain = domain, codomain = codomain }
  return arrow_type
}

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

  if _, ok := term.(True); ok do return base("Bool"), true
  if _, ok := term.(False); ok do return base("Bool"), true
  if _, ok := term.(Zero); ok do return base("Nat"), true

  if succ, ok := term.(Succ); ok {
    body_type, ok := typecheck(ctx, succ.body)
    if !ok do return nil, false
    body, body_has_base_type := body_type.(TypeBase)
    if !body_has_base_type do return nil, false
    if body.name != "Nat" do return nil, false
    return base("Nat"), true
  }

  if pred, ok := term.(Pred); ok {
    body_type, ok := typecheck(ctx, pred.body)
    if !ok do return nil, false
    body, body_has_base_type := body_type.(TypeBase)
    if !body_has_base_type do return nil, false
    if body.name != "Nat" do return nil, false
    return base("Nat"), true
  }

  if iszero, ok := term.(Is_Zero); ok {
    body_type, ok := typecheck(ctx, iszero.body)
    if !ok do return nil, false
    body, body_has_base_type := body_type.(TypeBase)
    if !body_has_base_type do return nil, false
    if body.name != "Nat" do return nil, false
    return base("Bool"), true
  }

  if if_statement, ok := term.(If); ok {
    cond_type, cond_ok := typecheck(ctx, if_statement.condition)
    if !cond_ok do return nil, false
    cond, cond_has_base_type := cond_type.(TypeBase)
    if !cond_has_base_type do return nil, false
    if cond.name != "Bool" do return nil, false

    cons_type, cons_ok := typecheck(ctx, if_statement.consequent)
    if !cons_ok do return nil, false
    
    alt_type, alt_ok := typecheck(ctx, if_statement.alternate)
    if !alt_ok do return nil, false

    if !are_same_type(cons_type, alt_type) do return nil, false
    
    return cons_type, true
  }

  if fix, ok := term.(Fix); ok {
    body_type, ok := typecheck(ctx, fix.body)
    if !ok do return nil, false

    fix_term, body_is_arrow := body_type.(TypeArrow)
    if !body_is_arrow do return nil, false
    if !are_same_type(fix_term.domain, fix_term.codomain) do return nil, false

    return fix_term.domain, true
  }

	unreachable()
}

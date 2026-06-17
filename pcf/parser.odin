package main

import "core:fmt"

Parser :: struct {
	tokens:  [dynamic]Token,
	current: int,
}

peek :: proc(p: ^Parser) -> Token {
	return p.tokens[p.current]
}

advance :: proc(p: ^Parser) -> Token {
	tok := p.tokens[p.current]
	p.current += 1
	return tok
}

expect :: proc(p: ^Parser, $T: typeid) -> bool {
	tok := advance(p)
	if _, ok := tok.(T); ok do return true
	fmt.eprintln("Parse error: Unexpected token")
	return false
}

expect_name :: proc(p: ^Parser) -> (string, bool) {
	tok := advance(p)
	if n, ok := tok.(TName); ok do return n.value, true
	fmt.eprintln("Parse error: Expected name")
	return "", false
}

expect_keyword :: proc(p: ^Parser, keyword: string) -> bool {
	tok := advance(p)
	tname, is_tname := tok.(TName)
	if !is_tname {
		fmt.eprintfln("Parse error: Expected keyword %s", keyword)
		return false
	}
	if tname.value != keyword {
		fmt.eprintfln("Parse error: Expected keyword %s", keyword)
		return false
	}
	return true
}

make_nat :: proc(n: int) -> ^Term {
	term := new(Term)
	term^ = n == 0 ? Zero{} : Succ{body = make_nat(n - 1)}
	return term
}

make_true :: proc() -> ^Term {
	term := new(Term)
	term^ = True{}
	return term
}

make_false :: proc() -> ^Term {
	term := new(Term)
	term^ = False{}
	return term
}

make_succ :: proc(body: ^Term) -> ^Term {
	term := new(Term)
	term^ = Succ {
		body = body,
	}
	return term
}

make_pred :: proc(body: ^Term) -> ^Term {
	term := new(Term)
	term^ = Pred {
		body = body,
	}
	return term
}

make_iszero :: proc(body: ^Term) -> ^Term {
	term := new(Term)
	term^ = Is_Zero {
		body = body,
	}
	return term
}

make_if :: proc(cond: ^Term, cons: ^Term, alt: ^Term) -> ^Term {
	term := new(Term)
	term^ = If {
		condition  = cond,
		consequent = cons,
		alternate  = alt,
	}
	return term
}

make_fix :: proc(body: ^Term) -> ^Term {
	term := new(Term)
	term^ = Fix {
		body = body,
	}
	return term
}

make_var :: proc(name: string) -> ^Term {
	term := new(Term)
	term^ = Var {
		name = name,
	}
	return term
}

make_abs :: proc(param: string, param_type: ^Type, body: ^Term) -> ^Term {
	term := new(Term)
	term^ = Abs{param, param_type, body}
	return term
}

make_app :: proc(m: ^Term, n: ^Term) -> ^Term {
	term := new(Term)
	term^ = App {
		rator = m,
		rand  = n,
	}
	return term
}

parse_tname :: proc(p: ^Parser, tname: ^TName) -> (^Term, bool) {
	switch tname.value {
	case "true":
		return make_true(), true
	case "false":
		return make_false(), true
	case "succ":
		body, ok := parse_term(p)
		if !ok do return nil, false
		return make_succ(body), true
	case "pred":
		body, ok := parse_term(p)
		if !ok do return nil, false
		return make_pred(body), true
	case "iszero":
		body, ok := parse_term(p)
		if !ok do return nil, false
		return make_iszero(body), true
	case "if":
		cond, cond_ok := parse_atom(p)
		if !cond_ok do return nil, false
		if !expect_keyword(p, "then") do return nil, false
		cons, cons_ok := parse_atom(p)
		if !cons_ok do return nil, false
		if !expect_keyword(p, "else") do return nil, false
		alt, alt_ok := parse_atom(p)
		if !alt_ok do return nil, false
		return make_if(cond, cons, alt), true
	case "fix":
		body, ok := parse_term(p)
		if !ok do return nil, false
		return make_fix(body), true
	case:
		return make_var(tname.value), true
	}
}

parse_atom :: proc(p: ^Parser) -> (^Term, bool) {
	tok := advance(p)

	if tname, ok := tok.(TName); ok {
		return parse_tname(p, &tname)
	} else if n, ok := tok.(TNumber); ok {
		return make_nat(n.value), true
	} else if _, ok := tok.(TLParen); ok {
		term, ok := parse_term(p)
		if !ok do return nil, false
		if !expect(p, TRParen) do return nil, false
		return term, true
	} else {
		fmt.eprintln("Parse error: Unexpected token")
		return nil, false
	}
}

parse_type :: proc(p: ^Parser) -> (^Type, bool) {
	domain: ^Type; ok1: bool

	if _, is_lparen := peek(p).(TLParen); is_lparen {
		advance(p)
		domain, ok1 = parse_type(p)
		if !ok1 do return nil, false
		if !expect(p, TRParen) do return nil, false
	} else {
		name, is_name := peek(p).(TName)
		if !is_name do return nil, false
		advance(p)
		domain = base(name.value)
	}

	if _, is_arrow := peek(p).(TArrow); !is_arrow do return domain, true
	advance(p)
	if codomain, ok := parse_type(p); ok do return arrow(domain, codomain), true
	return nil, false
}

parse_abs :: proc(p: ^Parser) -> (^Term, bool) {
	param: string; body: ^Term; param_type: ^Type; ok: bool

	advance(p)
	if param, ok = expect_name(p); !ok do return nil, false
	if !expect(p, TColon) do return nil, false
	if param_type, ok = parse_type(p); !ok do return nil, false
	if !expect(p, TDot) do return nil, false
	if body, ok = parse_term(p); !ok do return nil, false

	return make_abs(param, param_type, body), true
}

parse_app :: proc(p: ^Parser) -> (^Term, bool) {
	lhs, ok := parse_atom(p)
	if !ok do return nil, false

	for can_start_atom(p) {
		rhs, ok := parse_atom(p)
		if !ok do return nil, false
		lhs = make_app(lhs, rhs)
	}

	return lhs, true
}

can_start_atom :: proc(p: ^Parser) -> bool {
	_, isTLParen := peek(p).(TLParen)
	_, isTName := peek(p).(TName)
	_, isTNumber := peek(p).(TNumber)
	return isTLParen || isTName || isTNumber
}

parse_term :: proc(p: ^Parser) -> (^Term, bool) {
	_, isTLambda := peek(p).(TLambda)
	if isTLambda do return parse_abs(p)
	return parse_app(p)
}

parse :: proc(input: string) -> (^Term, bool) {
	tokens, ok := tokenise(input)
	if !ok do return nil, false
	p := Parser {
		tokens  = tokens,
		current = 0,
	}
	return parse_term(&p)
}

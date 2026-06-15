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
	fmt.eprintln("Unexpected token")
	return false
}

expect_name :: proc(p: ^Parser) -> (string, bool) {
	tok := advance(p)
	if n, ok := tok.(TName); ok do return n.value, true
	fmt.eprintln("Expected name")
	return "", false
}

parse_atom :: proc(p: ^Parser) -> (^Term, bool) {
	tok := advance(p)
	if v, ok := tok.(TName); ok {
		term := new(Term)
		term^ = Var {
			name = v.value,
		}
		return term, true
	} else if _, ok := tok.(TLParen); ok {
		term, parse_ok := parse_term(p)
		if !parse_ok do return nil, false
		if !expect(p, TRParen) do return nil, false
		return term, true
	} else {
		fmt.eprintln("Unexpected token")
		return nil, false
	}
}

parse_abs :: proc(p: ^Parser) -> (^Term, bool) {
	param: string; body: ^Term; ok: bool

	advance(p)                                              // λ
	if param, ok = expect_name(p); !ok do return nil, false // <name>
	if !expect(p, TDot) do return nil, false                // .
	if body, ok = parse_term(p); !ok do return nil, false   // term

	term := new(Term)
	term^ = Abs{param, body}
	return term, true
}

parse_app :: proc(p: ^Parser) -> (^Term, bool) {
	lhs: ^Term; ok: bool
	if lhs, ok = parse_atom(p); !ok do return nil, false

	for can_start_atom(p) {
		rhs, ok := parse_atom(p)
		if !ok do return nil, false
		app := new(Term)
		app^ = App{lhs, rhs}
		lhs = app
	}

	return lhs, true
}

can_start_atom :: proc(p: ^Parser) -> bool {
	_, isTLParen := peek(p).(TLParen)
	_, isTName := peek(p).(TName)
	return isTLParen || isTName
}

parse_term :: proc(p: ^Parser) -> (^Term, bool) {
	_, isTLambda := peek(p).(TLambda)
	if isTLambda do return parse_abs(p)
	return parse_app(p)
}

parse :: proc(input: string) -> (^Term, bool) {
	tokens, tokenise_ok := tokenise(input)
	if !tokenise_ok do return nil, false

	p := Parser { tokens = tokens, current = 0 }
	return parse_term(&p)
}

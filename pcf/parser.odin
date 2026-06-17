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

expect_keyword :: proc(p: ^Parser, keyword: string) -> bool {
	tok := advance(p)
	tname, is_tname := tok.(TName)
	if !is_tname {
		fmt.eprintfln("Expected keyword %s", keyword)
		return false
	}
	if tname.value != keyword {
		fmt.eprintfln("Expected keyword %s", keyword)
		return false
	}
	return true
}

make_nat :: proc(n: int) -> ^Term {
	term := new(Term)
  term^ = n == 0 ? Zero{} : Succ { body = make_nat(n - 1)}
	return term
}

parse_atom :: proc(p: ^Parser) -> (^Term, bool) {
	tok := advance(p)
	if v, ok := tok.(TName); ok {
		term := new(Term)
		if v.value == "true" do term^ = True{}
		else if v.value == "false" do term^ = False{}
		else if v.value == "succ" {
			body, ok := parse_term(p)
			if !ok do return nil, false
			term^ = Succ {
				body = body,
			}
		} else if v.value == "pred" {
			body, ok := parse_term(p)
			if !ok do return nil, false
			term^ = Pred {
				body = body,
			}
		} else if v.value == "iszero" {
			body, ok := parse_term(p)
			if !ok do return nil, false
			term^ = Is_Zero {
				body = body,
			}
		} else if v.value == "if" {
			cond, cond_ok := parse_atom(p)
			if !cond_ok do return nil, false

			if !expect_keyword(p, "then") do return nil, false
			cons, cons_ok := parse_atom(p)
			if !cons_ok do return nil, false

			if !expect_keyword(p, "else") do return nil, false
			alt, alt_ok := parse_atom(p)
			if !alt_ok do return nil, false
			term^ = If{cond, cons, alt}
		} else if v.value == "fix" {
			body, ok := parse_term(p)
			if !ok do return nil, false
			term^ = Fix {
				body = body,
			}
		} else do term^ = Var {
			name = v.value,
		}
		return term, true
	} else if n, ok := tok.(TNumber); ok {
    return make_nat(n.value), true
	} else if _, ok := tok.(TLParen); ok {
		term, ok := parse_term(p)
		if !ok do return nil, false
		if !expect(p, TRParen) do return nil, false
		return term, true
	} else {
		fmt.eprintln("Unexpected token")
		return nil, false
	}
}

parse_type :: proc(p: ^Parser) -> (^Type, bool) {
	domain: ^Type; ok: bool

	if _, is_lparen := peek(p).(TLParen); is_lparen {
		advance(p)
		domain, ok = parse_type(p)
		if !ok do return nil, false
		if !expect(p, TRParen) do return nil, false
	} else {
		name, is_name := peek(p).(TName)
		if !is_name do return nil, false
		advance(p)
		base := new(Type)
		base^ = TypeBase {
			name = name.value,
		}
		domain = base
	}

	if _, ok1 := peek(p).(TArrow); !ok1 do return domain, true
	advance(p)
	codomain, ok2 := parse_type(p)
	if !ok2 do return nil, false
	arrow := new(Type)
	arrow^ = TypeArrow {
		domain   = domain,
		codomain = codomain,
	}
	return arrow, true
}

parse_abs :: proc(p: ^Parser) -> (^Term, bool) {
	param: string; body: ^Term; param_type: ^Type; ok: bool

	advance(p) // λ
	if param, ok = expect_name(p); !ok do return nil, false // <name>
	if !expect(p, TColon) do return nil, false // :
	if param_type, ok = parse_type(p); !ok do return nil, false // <type>
	if !expect(p, TDot) do return nil, false // .
	if body, ok = parse_term(p); !ok do return nil, false // <term>

	term := new(Term)
	term^ = Abs{param, param_type, body}
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

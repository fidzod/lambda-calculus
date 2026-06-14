package main

import "core:fmt"

main :: proc() {
	ast: ^Term; ok: bool

	if ast, ok = parse(`(\x:i. x) x`); ok do fmt.println(term_to_string(ast))
	if ast, ok = parse(`\f:i->i. \x:i. f x`); ok do fmt.println(term_to_string(ast))
}

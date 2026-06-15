package main

import "core:fmt"

Token :: union {
	TLambda,
	TLParen,
	TRParen,
	TName,
	TDot,
	TEOF,
}

TLambda :: struct {}
TLParen :: struct {}
TRParen :: struct {}
TName   :: struct { value: string }
TDot    :: struct {}
TEOF    :: struct {}

tokenise :: proc(input: string) -> ([dynamic]Token, bool) {
	tokens := make([dynamic]Token)

	for i := 0; i < len(input); {
		char := input[i]

		switch char {
		case ' ', '\t', '\n':
			i += 1
		case '(':
			append(&tokens, TLParen{})
			i += 1
		case ')':
			append(&tokens, TRParen{})
			i += 1
		case '\\':
			append(&tokens, TLambda{})
			i += 1
		case '.':
			append(&tokens, TDot{})
			i += 1
		case:
			if is_alpha(char) {
				start := i
				for i < len(input) && is_alpha(input[i]) do i += 1
				append(&tokens, TName{value = input[start:i]})
			} else {
				fmt.eprintln("Error: Invalid character:", char)
				delete(tokens)
				return {}, false
			}
		}
	}

	append(&tokens, TEOF{})

	return tokens, true
}

is_alpha :: proc(c: u8) -> bool {
	return (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || c == '_' || c == '?'
}

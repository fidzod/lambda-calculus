package main

import "core:strconv"
import "core:fmt"

Token :: union {
	TLambda,
	TLParen,
	TRParen,
	TName,
  TNumber,
	TDot,
	TColon,
	TArrow,
	TEOF,
}

TLambda :: struct {}
TLParen :: struct {}
TRParen :: struct {}
TName :: struct {
	value: string,
}
TNumber :: struct {
  value: int
}
TDot :: struct {}
TColon :: struct {}
TArrow :: struct {}
TEOF :: struct {}

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
		case ':':
			append(&tokens, TColon{})
			i += 1
    case '-':
      if i + 1 >= len(input) {
				fmt.eprintln("Error: Invalid character:", char)
				delete(tokens)
				return {}, false
      }
      if input[i+1] == '>' {
        append(&tokens, TArrow{})
        i += 2
      }
      else {
				fmt.eprintln("Error: Invalid character:", char)
				delete(tokens)
				return {}, false
      }
		case:
			if is_alpha(char) {
				start := i
				for i < len(input) && is_alpha(input[i]) do i += 1
				append(&tokens, TName{value = input[start:i]})
			} else if is_number(char) {
				start := i
				for i < len(input) && is_number(input[i]) do i += 1
        value, ok := strconv.parse_int(input[start:i])
        if !ok {
          fmt.eprintln("Error: Failed to parse number")
          return {}, false
        }
				append(&tokens, TNumber{value = value})
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

is_number :: proc(c: u8) -> bool {
	return (c >= '0' && c <= '9')
}

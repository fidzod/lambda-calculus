package main

import "core:fmt"
import "core:os"
import "core:strings"

expand :: proc(input: string, env: map[string]string) -> string {
	tokens, ok := tokenise(input)
	if !ok do return input
	defer delete(tokens)

	result := make([dynamic]string)
	defer delete(result)

	for tok in tokens {
		switch t in tok {
		case TName:
			if t.value in env {
				append(&result, fmt.tprintf("(%s)", env[t.value]))
			} else {
				append(&result, t.value)
			}
		case TLParen:
			append(&result, "(")
		case TRParen:
			append(&result, ")")
		case TLambda:
			append(&result, "\\")
		case TDot:
			append(&result, ".")
		case TEOF:
		}
	}
	return strings.join(result[:], " ")
}

eval_line :: proc(line: string, env: ^map[string]string) -> (string, bool) {
	trimmed := strings.trim_space(line)
	if trimmed == "" do return "", true

	fields := strings.fields(trimmed)
	defer delete(fields)

	if fields[0] == "let" {
		if len(fields) < 4 || fields[2] != "=" {
			fmt.eprintln("Error: invalid let syntax")
			return "", false
		}
		name := strings.clone(fields[1])
		body := strings.join(fields[3:], " ")
		expanded := expand(body, env^)
		env[name] = expanded
		return "", true
	}

	if fields[0] == "import" {
		if len(fields) < 2 {
			fmt.eprintln("Error: invalid import syntax")
			return "", false
		}
		path := fmt.tprintf("%s.lc", fields[1])
		if !load_file(path, env) do return "", false
		return "", true
	}

	expanded := expand(trimmed, env^)
	term, ok := parse(expanded)
	if !ok do return "", false
	reduced, ok2 := reduce(term)
	if !ok2 {
		fmt.eprintln("Error: no normal form found")
		return "", false
	}
	return term_to_string(reduced), true
}

load_file :: proc(path: string, env: ^map[string]string) -> bool {
	data, err := os.read_entire_file(path, context.allocator)
	if err != os.ERROR_NONE {
		fmt.eprintln("Error: could not read file:", path)
		return false
	}
	defer delete(data)

	lines := strings.split_lines(string(data))
	defer delete(lines)

	for line in lines {
		result, ok := eval_line(line, env)
		if !ok do return false
		if result != "" do fmt.println(result)
	}
	return true
}

package main

import "core:fmt"
import "core:os"
import "core:strings"

expand :: proc(input: string, env: map[string]string) -> string {
	tokens, tokenise_ok := tokenise(input)
	if !tokenise_ok do return input
	defer delete(tokens)

	expanded := make([dynamic]string)
	defer delete(expanded)

	for tok in tokens {
		switch t in tok {
		case TName:
			if t.value in env {
				append(&expanded, fmt.tprintf("(%s)", env[t.value]))
			} else {
				append(&expanded, t.value)
			}
		case TLParen:
			append(&expanded, "(")
		case TRParen:
			append(&expanded, ")")
		case TLambda:
			append(&expanded, "\\")
		case TDot:
			append(&expanded, ".")
		case TEOF:
		}
	}
	return strings.join(expanded[:], " ")
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

    term, parse_ok := parse(expanded)
    if !parse_ok {
      fmt.eprintln("Error: failed to parse let expression body")
      return "", false
    }

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

	term, parse_ok := parse(expanded)
	if !parse_ok do return "", false
	if !parse_ok {
		fmt.eprintln("Error: failed to parse")
		return "", false
	}

	reduced, reduce_ok := reduce(term)
	if !reduce_ok {
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
		result, eval_ok := eval_line(line, env)
		if !eval_ok do return false
		if result != "" do fmt.println(result)
	}
	return true
}

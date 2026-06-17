package main

import "core:fmt"
import "core:mem"
import "core:os"
import "core:strings"

expand :: proc(input: string, env: map[string]string) -> string {
	tokens, tokenise_ok := tokenise(input)
	if !tokenise_ok do return input

	expanded := make([dynamic]string)

	for tok in tokens {
		switch t in tok {
		case TName:
			if t.value in env {
				append(&expanded, fmt.tprintf("(%s)", env[t.value]))
			} else {
				append(&expanded, t.value)
			}
		case TNumber:
			append(&expanded, fmt.tprintf("%d", t.value))
		case TLParen:
			append(&expanded, "(")
		case TRParen:
			append(&expanded, ")")
		case TLambda:
			append(&expanded, "\\")
		case TDot:
			append(&expanded, ".")
		case TColon:
			append(&expanded, ":")
		case TArrow:
			append(&expanded, "->")
		case TEOF:
		}
	}
	return strings.join(expanded[:], " ")
}

eval_line :: proc(line: string, env: ^map[string]string) -> (string, bool) {
	heap_allocator := context.allocator

	arena_mem := make([]byte, 400 * mem.Megabyte, heap_allocator)
	arena: mem.Arena
	mem.arena_init(&arena, arena_mem)
	defer delete(arena_mem, heap_allocator)

	context.allocator = mem.arena_allocator(&arena)

	trimmed := strings.trim_space(line)
	if trimmed == "" do return "", true

	fields := strings.fields(trimmed)

	if fields[0] == "let" {
		if len(fields) < 4 || fields[2] != "=" {
			fmt.eprintln("Error: invalid let syntax")
			return "", false
		}
		name := strings.clone(fields[1], heap_allocator)
		body := strings.join(fields[3:], " ", heap_allocator)
		expanded := expand(body, env^)
		delete(body, heap_allocator)

		term, parse_ok := parse(expanded)
		if !parse_ok {
			fmt.eprintln("Error: failed to parse let expression body")
			return "", false
		}

		ctx := make(map[string]^Type)
		type, typecheck_ok := typecheck(ctx, term)
		if !typecheck_ok {
			fmt.eprintln("Error: typecheck failed")
			return "", false
		}

		fmt.printfln("%s = %s : %s", name, term_to_string(term), type_to_string(type))

		env[name] = strings.clone(expanded, heap_allocator)
		return "", true
	}

	expanded := expand(trimmed, env^)

	term, parse_ok := parse(expanded)
	if !parse_ok do return "", false
	if !parse_ok {
		fmt.eprintln("Error: failed to parse")
		return "", false
	}

	ctx := make(map[string]^Type)
	type, typecheck_ok := typecheck(ctx, term)
	if !typecheck_ok {
		fmt.eprintln("Error: typecheck failed")
		return "", false
	}

	reduced, reduce_ok := reduce(term)
	if !reduce_ok {
		fmt.eprintln("Error: no normal form found")
		return "", false
	}

	result := strings.clone(term_to_string(reduced), heap_allocator)
	return result, true
}

flush :: proc(buf: string, env: ^map[string]string, ln: int) -> bool {
	trimmed := strings.trim_space(buf)
	if trimmed == "" do return true
	result, ok := eval_line(trimmed, env)
	if !ok {
		fmt.eprintfln("Error on line %d", ln)
		return false
	}
	if result != "" do fmt.println(result)
	return true
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

	buffer := ""
	line_start := 0

	for line, ln in lines {
		is_continuation := len(line) > 0 && (line[0] == ' ' || line[0] == '\t')
		if is_continuation {
			buffer = strings.join({buffer, line}, " ")
		} else {
			if !flush(buffer, env, line_start) do return false
			buffer = line
			line_start = ln
		}
	}
	if !flush(buffer, env, line_start) do return false

	return true
}

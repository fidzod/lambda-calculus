package main

import "core:fmt"
import "core:os"

main :: proc() {
	env := make(map[string]string)
	defer delete(env)

	args := os.args[1:]

	switch len(args) {
	case 0:
		repl(&env)
	case 1:
		load_file(args[0], &env)
	case 2:
		if args[0] == "-i" {
			if !load_file(args[1], &env) do os.exit(1)
			repl(&env)
		} else {
			fmt.eprintln("Usage: lc [file.lc] [-i file.lc]")
			os.exit(1)
		}
	case:
		fmt.eprintln("Usage: lc [file.lc] [-i file.lc]")
		os.exit(1)
	}
}

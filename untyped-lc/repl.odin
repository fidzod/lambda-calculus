package main

import "core:fmt"
import "core:os"
import "core:strings"

repl :: proc(env: ^map[string]string) {
	buf: [256]byte
	for {
		fmt.print("λ> ")
		n, err := os.read(os.stdin, buf[:])
		if err != nil do break
		input := strings.trim_right(string(buf[:n]), "\n\r")
		if input == "quit" do break
		result, ok := eval_line(input, env)
		if ok && result != "" do fmt.println(result)
	}
}

package main

import "core:fmt"

main :: proc() {
  term, ok := parse(`(\x. x) x`)
  if ok do fmt.println(term_to_string(term))  // ((λx. x) x)
}

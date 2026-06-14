package main

Type :: union {
	TypeBase,
	TypeArrow,
}

TypeBase :: struct {
	name: string,
}

TypeArrow :: struct {
	domain:   ^Type,
	codomain: ^Type,
}

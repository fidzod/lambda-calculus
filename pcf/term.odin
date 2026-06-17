package main

Term :: union {
	Var,
	Abs,
	App,
	True,
	False,
	Zero,
	Succ,
  Pred,
  Is_Zero,
  If,
  Fix,
}

Var :: struct {
	name: string,
}

Abs :: struct {
	param:      string,
	param_type: ^Type,
	body:       ^Term,
}

App :: struct {
	rator: ^Term,
	rand:  ^Term,
}

True  :: struct {}
False :: struct {}
Zero  :: struct {}

Succ :: struct {
	body: ^Term,
}

Pred :: struct {
  body: ^Term,
}

Is_Zero :: struct {
  body: ^Term,
}

If :: struct {
  condition: ^Term,
  consequent: ^Term,
  alternate: ^Term,
}

Fix :: struct {
  body: ^Term,
}

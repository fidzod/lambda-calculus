# Lambda Calculus Interpreter in Odin

Read the blog post that accompanies this project
[here](https://tobyjordan.com/blog/lambda-calculus-interpreter-in-odin).

## Building

To build, just run `odin run build`.

## Usage

- `./lambda-calculus` Run the REPL

- `./lambda-calculus -i std.lc` Import `std.lc` and run the REPL

- `./lambda-calculus examples/insertion_sort.lc` Evaluate `insertion_sort.lc`

## Example Program

Insertion sort over a list of Church numerals:

```text
let insert = Y (\go. \n. \l.
  if (nil? l)
    (cons n nil)
    (if (lte? n (head l))
      (cons n l)
      (cons (head l) (go n (tail l)))))

let sort = Y (\go. \l.
  if (nil? l)
    nil
    (insert (head l) (go (tail l))))

let sorted = sort (cons three (cons two (cons five (cons four nil))))
```

---
layout: page
title: "PA1 – Simple Compiler with Binary Operations"
doodle: "../doodle.png"
---

# PA1 Anaconda, Due Wednesday 4/18/2018

In this assignment you'll implement a compiler for a small language called
Anaconda, that has let bindings and binary operators.




## Setup

Get the assignment [here](https://classroom.github.com/a/9yAM_1kp)

If you are working on your own computer, install the Ocaml library
core with `opam install core`. This will take a while, but is needed
for the S-expression parsing we will be using. Note that the version of
Core (and Ocaml) will not match between ieng6 and gradescope(or your 
computer), so it is your responsibility to ensure your code compiles
properly. You should avoid using Core functionality outside of
the small portion needed for S-expressions for this reason.

## The Anaconda Language

In each of the next several assignments, we'll introduce a language that we'll
implement.  We'll start small, and build up features incrementally.  We're
starting with Anaconda, which has just a few features – defining variables, and
primitive operations on numbers.

There are a few pieces that go into defining a language for us to compile:
* A description of the concrete syntax – the text the programmer writes.
* A description of the abstract syntax – how to express what the
  programmer wrote in a data structure our compiler uses.
* A *description of the behavior* of the abstract
  syntax, so our compiler knows what the code it generates should do.

### Concrete Syntax

The concrete syntax of Anaconda is:

```
<expr> :=
  | <number>
  | <identifier>
  | (let (<bindings>) (<expr>))
  | (add1 <expr>)
  | (sub1 <expr>)
  | (+ <expr> <expr>)
  | (- <expr> <expr>)
  | (* <expr> <expr>)

<bindings> :=
  | (<identifier> <expr>)
  | (<identifier> <expr>) <bindings>
```
Here, a `let` expression can have one *or more* bindings.

### Abstract Syntax

The abstract syntax of Anaconda is an OCaml datatype, and corresponds nearly
one-to-one with the concrete syntax.

```
type prim1 =
  | Add1
  | Sub1

type prim2 =
  | Plus
  | Minus
  | Times

type expr =
  | Number of int
  | Id of string
  | Let of (string * expr) list * expr
  | Prim1 of prim1 * expr
  | Prim2 of prim2 * expr * expr
```

### Semantics

An Anaconda program always evaluates to a single integer. <code>**Number**s</code> evaluate to
themselves (so a program just consisting of `Number(5)` should evaluate to the
integer `5`).
Primitive expressions perform addition or subtraction by one on
their argument.
Binary operator expressions evaluate their arguments and combine them
based on the operator.
Let bindings should evaluate all the binding expressions to
values one by one, and after each, store a mapping from the given name to the
corresponding value in both (a) the rest of the bindings, and (b) the body of
the let expression. Identifiers evaluate to whatever their current stored
value is.
There are several examples further down to make this concrete.

The compiler should signal an error if:

* There is a binding list containing two or more bindings with the same name
* An identifier is unbound (there is no surrounding let binding for it)

Here are some examples of Anaconda programs:

#### Example 1

**Concrete Syntax**

```scheme
5               
```

**Abstract Syntax**

```ocaml
Number(5)
```

**Result**

```
5      
```

#### Example 2

**Concrete Syntax**

```scheme
(sub1 (add1 (sub1 5)))
```

**Abstract Syntax**

```ocaml
Prim1(Sub1, Prim1(Add1, Prim1(Sub1, Number(5))))
```

**Result**

```
4
```

#### Example 3

**Concrete Syntax**

```scheme
(let ((x 5)) (add1 x))
```

**Abstract Syntax**

```ocaml
Let([("x", Number(5))], Prim1(Add1, Id("x")))
```

**Result**

```
6
```

#### More examples
```
(sub1 5)
# as an expr
Prim1(Sub1, Number(5))
# evaluates to
4
```

```
(let ((x 10) (y 9)) (* (- x y) 2))
# as an expr
Let([("x", Number(10)), ("y", Number(9))],
  Prim2(Times, Prim2(Minus, Id("x"), Id("y")), Number(2)))
# evaluates to
2
```

### Implementing a Compiler for Anaconda

You've been given a starter codebase that has several pieces of
infrastructure:

* A parser for Anaconda which takes a s-expression that represents the code,
  and converts it to an abstract syntax tree (`parser.ml`). You need to
  implement the parser to actually perform the conversion, although a portion
  involving converting to a number or id is implemented as an example.
* A main program (`main.ml`) that uses the parser and compiler to produce
  assembly code from an input Anaconda text file.  You don't need to edit this.
* A `Makefile` that builds `main.ml`, builds a tester for Anaconda
  (`test.ml`), and manipulates assembly programs created by the Anaconda
  compiler.  You don't need to edit the `Makefile` or `test.ml`, but you
  will edit `myTests.ml`.
  Specifically, you will add your own tests by filling in
  `myTestList` following the instructions in the beginning of the file.

  You need to add _at least 5 tests_ to `myTests.ml`. For this assignment,
  we will not explicitly evaluate your test cases. Focus on making these 
  interesting and thorough, however, as in future assignments we will directly
  assess your test cases.
* An OCaml program (`runner.ml`) that works in concert with the `Makefile` to
  allow you to compile and run an Anaconda program from within OCaml, which is
  quite useful for testing.  You don't need to edit `runner.ml`.

All of your edits—which will be to write the compiler for Anaconda, and test
it—will happen in `parser.ml`, `compile.ml`, `asm.ml` and `myTests.ml`.
Do not edit `expr.ml`, `test.ml`, `runner.ml`, or `main.ml`.

### Writing the Parser

The parser will be given a S-expression representing the whole program, and
must build a AST of the `expr` data type (refer to `expr.ml`) from this S-expression.

An S-expression in OCaml (from the Core library) is of the following type:
```
type sexp =
| List of sexp list
| Atom of string
```
For more info about S-expressions in Core, see [here](https://dev.realworldocaml.org/data-serialization.html)
This is a new version of realworldocaml and is in progress, so it may have
errors. It likely will not match the version of core on ieng6 for any syntax
extensions,  as that version is somewhat dated.

Thus, an example S-expression that could be parsed into a program would be as
follows
```
List([Atom("let"); List([List([Atom("x"); Atom("5")])]) Atom("x")])
```
which corresponds to
```
(let ((x 5)) x)
```
in anaconda or
```
let x = 5 in x
```
in OCaml.

This should then parse to the AST
```
ELet([("x",ENumber(5))],EId("x"))
```
which can then be compiled.

Since most S-expressions are lists, you will need to check the first element
of the list to see if the operation to perform is a `let`, `add1`, `*`, and so
on. If a S-expression is of an invalid form, (i.e. a `let` with no body, a `+`
with three arguments, etc.) report an appropriate error using failwith.

You can assume that an id is a valid string of form `[a-zA-z][a-zA-Z0-9]*`.
You will, however, have to check that the string does not match any of
the language's reserved words, such as `let`, `add1`, and `sub1`.

The parsing should be implemented in
```
parse: sexp -> expr
```
There is also an added function parse_binding,
```
parse_binding: sexp -> (string, expr)
```
which may be helpful for handling `let` expressions.

### Writing the Compiler

The primary task of writing the Anaconda compiler is simple to state: take an
instance of the `expr` datatype and turn it into a list of assembly
instructions.  The provided compiler skeleton is set up to do just this,
broken up over a few functions.

The first is
```
compile : expr -> instruction list
```

which takes an `expr` value (abstract syntax) and turns it into a list of
assembly instructions, represented by the `instruction` type.  Use only the
provided instruction types for this assignment; we will be gradually expanding
this as the quarter progresses.  This function has an associated helper that
takes some extra arguments to track the variable environment and stack
offset.  These will be discussed in more detail in lecture. `compile` also
calls some other helper functions that help us seperate out the code,
it is up to you to use these or not.

**Note**: For variable bindings, we use a `(string * int) list`.  
  This is a simple data structure that's often called an association list.  
  There is a provided `find` function that looks up a value (an `int`) by key
  (a `string`).  Adding to an association list is trivial – simply add onto 
  the front with `::`.  You are responsible for understanding how ordering
  in the case of duplicate keys may interact with scope.

The other component you need to implement is:

```
i_to_asm : instruction -> string
```

which is found in `asm.ml`. It renders individual instances of the instruction datatype into a string
representation of the instruction (this is done for you for `mov` and `ret`).
This second step is straightforward, but forces you to understand the syntax
of the assembly code you are generating.  Most of the compiler concepts happen
in the first step, that of generating assembly instructions from abstract
syntax.  Do use [this assembly guide](http://www.cs.virginia.edu/~evans/cs216/guides/x86.html)
if you have questions about the concrete syntax of an instruction.
You should also fill out the rest of `arg_to_asm : arg -> string` to support the `RegOffset`
datatype, which will enable memory accesses (see stackloc in `compile.ml` and
the assembly reference for help).

### Assembly instructions
The assembly instructions that you will have to become familiar with for this
assignment are:

* `IMov of arg * arg` — Copies the right operand (source) into the left operand
  (destination). The source can be an immediate argument, a register or a
  memory location, whereas the destination can be a register or a memory
  location.

  Examples:
  ```
    mov eax, ebx
    mov [eax], 4
  ```

* `IAdd of arg * arg` — Add the two operands, storing the result in its first
  operand.

  Example: `add eax, 10`

* `ISub of arg * arg` — Store in the value of its first operand the result of
  subtracting the value of its second operand from the value of its first
  operand.

  Example: `sub eax, 216`

* `IMul of arg * arg` — Multiply the left argument by the right argument, and
  store in the left argument (typically the left argument is `eax` for us)

  Example: `imul eax, 4`

### Running main

The `main` program built with `make main` takes a single file as its
command-line argument, and outputs the compiled assembly string on standard
out. Note the `.ana` extension.

```
$ make main
$ ./main input/forty_two.ana
section .text
global our_code_starts_here
our_code_starts_here:
  mov eax, 42
  ret
```

To actually evaluate your assembly code, first we must create a `.s` assembly file, and
then link it with `main.c` to create an executable.
```
$ make output/forty_two.s (create the assembly file)
$ make output/forty_two.run (create the executable)
```
Finally you can run the file by executing to see the evaluated output:
```
$ ./output/forty_two.run
```

### Testing the Compiler

The test file has the helper function `t` that will be useful to you:

```
t : string -> string -> string -> OUnit.test
```
The first string given to `t` (test) is a test name, followed by an Anaconda
program (in concrete syntax) to compile and evaluate, followed by a string for
the expected output of the program (this will just be an integer in quotes).
This helper compiles, links, and runs the given program, and if the compiler
ends in error, it will report the error message as a string.  This includes
problems building at the assembler/linker level, as well as any explicit
`failwith` statements in the compiler itself.

If your tests do not have any errors, a `.s` file and `.run` executable is generated
in the `output/` directory, containing the compiled assembly code and executable
for that case.

You can test all the provided tests and the tests you have provided in @tt{myTests.ml}
by running
```
$ make test
$ ./test
```
This should report all tests that fail to compile or diverge from the specified
result.


There is also a function `t_err` that will help with testing for errors:
```
t_err : string -> string -> string -> OUnit.test
```
This will let you check that error messages are correctly printed by your
compiler.

**Note**: You should name your tests, but keep in mind that test
names cannot have spaces; this is due to the way the `Makefile`
relies on test names being used for filenames.

**Debug/Protip**: Check your assembly files as a means of debugging your code. If you can work through
the assembly and identify incorrect assembly instructions, you can trace the problem back to your compiler!
Furthermore, you can manually edit your `.s` to see what some assembly code may evaluate to.

---
layout: page
title: "PA3 – Cobra"
doodle: "http://animals.sandiegozoo.org/sites/default/files/2016-11/animals_hero_cobra.jpg"
---

# PA3 Cobra, Due Wednesday 5/02/2018 (Closed Collaboration)

[Get your repo here](https://classroom.github.com/a/VYutD1VP)

In this assignment you'll implement a small language called Cobra, which
extends on Boa by adding functions, including the `our_main` function (which
is called by `our_code_starts_here` and acts as the starting point for a
Cobra executable), and the ability to call the C `print` function from Cobra.

## The Cobra Language

As usual, there are a few pieces that go into defining a language for us to
compile.

- A description of the concrete syntax – the text the programmer writes

- A description of the abstract syntax – how to express what the
  programmer wrote in a data structure our compiler uses.

- The _semantics_—or description of the behavior—of the abstract
  syntax, so our compiler knows what the code it generates should do.


### Concrete Syntax

The concrete syntax of Boa is:

```
<program> :=
  | ((define our_main (input) <expr>))
  | (<definition list> (define our_main (input) <expr>))

<definition list> :=
  | <definition>
  | <definition> <definition list>

<definition> :=
  | (define <identifier> () <expr>)
  | (define <identifier> (<parameter list>) <expr>)

<parameter list> :=
  | <identifier>
  | <identifier> <parameter list>

<expr> :=
  | (let (<bindings>) <expr>)
  | (if <expr> <expr> <expr>)
  | <identifier>
  | <number>
  | true
  | false
  | (add1 <expr>)
  | (sub1 <expr>)
  | (isNum <expr>)
  | (isBool <expr>)
  | (+ <expr> <expr>)
  | (- <expr> <expr>)
  | (* <expr> <expr>)
  | (< <expr> <expr>)
  | (> <expr> <expr>)
  | (== <expr> <expr>)
  | (print <expr>)
  | <function app>

<bindings> :=
  | (<identifier> <expr>)
  | (<identifier> <expr>) <bindings>

<function app> :=
  | (<identifier>)
  | (<identifier> <expr list>)

<expr list> :=
  | <expr>
  | <expr> <expr list>
```

### Abstract Syntax

The abstract syntax of Cobra is an OCaml datatype, and corresponds nearly
one-to-one with the concrete syntax.

```
type prim1 =
  | Add1
  | Sub1
  | IsNum
  | IsBool

type prim2 =
  | Plus
  | Minus
  | Times
  | Less
  | Greater
  | Equal

type expr =
  | ELet of (string * expr) list * expr
  | EIf of expr * expr * expr
  | EId of string
  | ENumber of int
  | EBool of bool
  | EPrim1 of prim1 * expr
  | EPrim2 of prim2 * expr * expr
  | EApp of string * expr list
  | EPrint of expr 

type functype =
  | DFun of string * string list * expr

type program =
  | Program of functype list
```

### Semantics

There are three main changes that ripple through the implementation:

- All Cobra code is now executed inside a Cobra function, including `our_main`.
- Functions, including `our_main` are defined using the `define` keyword, and
  can be called (including recursively).
- A new operator `print`, which prints using the C function.

## Functions

Functions in Cobra can be defined using the `define` keyword, and require both a 
list of formal parameters and a function body. The formal parameters represent
variables that can be used inside the function body, and will take a specific
value when the function is called. Note, however, that a function can be called from
any other function, regardless of the order in which they appear.
For example, we can have the following code:

```
((define add5 (n) (+ n 5))
 (define our_main (input) (add5 input))
```

The code works as follows:

1. We define a function `add5` with one argument (named `n`) which adds `5` to
its argument and returns the result. The return value of the function is
whatever its body evaluates to when the formal parameters are given concrete
values and added to the environment.
2. We then define the function `our_main` (like `main` in C) with one argument
(named `input`) which calls `add5`, passing `input` as the single argument.
3. We can then run the program, providing some command line input like `6`. At
runtime (the representation of) `6` will be passed to `our_main`, which will then
call `add5`, passing (the representation of) `6` as the argument.
4. `add5` will then take its argument, add `5` to it, and return the result.
5. `our_main` immediately returns the result of the call to `add5`, which is
then printed in `main.c`.

You will need to generalize the techniques for single-argument functions
demonstrated in class to multi-argument functions. You are welcome to build on
the calling convention presented in class, or make your own convention entirely.
The only requirement (other than the functional requirements, i.e. producing the
correct value) is that running `valgrind` on your compiled code that uses
function calls must pass cleanly, with no invalid reads, writes, etc. `valgrind`
is configured on ieng6 to work with 32-bit executables, so you can test your
code there.

## Handling `input`

As in the last assignment, the variable `input` in Cobra represents the command
line input provided to the executable. The key difference is that `input` is now
an explicit argument to the `our_main` function. This can be passed in either
through the standard method, from `main.c`, or through a recursive call. To aid
with this, we have given a snippet of assembly that will convert from the C
calling convention to the suggested Cobra calling convention, which we'll call
`our_main.`

## C Calling Convention

When calling a function, we must follow the calling convention that it assumed
when it was compiled. Therefore, in order to call C functions we should follow
the appropriately named C calling convention. For example, suppose that we
wish to call the function `foo( int x, int y, int z )`, which is defined in C, with
parameters `x = 1, y = 2, z = 3`. In order to call our function, we do as follows:

1. Push each argument in reverse order, which causes `ESP` to change
```
push 3
push 2
push 1
```
2. Call the function
```
call foo
```
3. Place `ESP` back to its original location. In this case, since we pushed
three values onto the stack, we must move `ESP` back down three words
```
add esp, 12
```

Note that we did not have to do step 3 when we handled runtime errors as we
are not expecting to return back to our assembly code and instead exit completely
out of the program. Also, managing `EBP` and moving `ESP` forward is the
responsibility of the callee in the C calling convention, thus we do not manage them
when calling `print`.

#### The check function

The `check` function will have to be extended to handle `programs` rather than
just `expr`s, including function definitions.

The errors you need to check for include:

- Duplicate function names: all function names must be unique, just like in C.
  Your error message for this case must contain `"Duplicate function name"`.
- `our_main`: the function `our_main` must be present, and must have a single
  argument to match the expectations of our C code in `main.c`. If the
  `our_main` function is present and doesn't have exactly one argument, then
  your error message must contain `"Invalid"`. If `our_main` is not present,
  your error message must contain `"Missing our_main"`.
- Duplicate formal parameters: all the formal parameters for one function must
  have unique names. For example, `(define foo (x x) (+ x x))` is invalid. Your
  error message for this case must contain `"Duplicate arg"`.
- Arity errors: when a function is applied, you must check that the number of
  arguments given matches the number of arguments expected. Your error message
  must contain `"Arity"`.
- Application of an unknown function: if someone attempts to apply something
  that isn't a function, or no function by that name is defined, you should
  report an error. Your error message must contain `"No such function"`.

## Implementing Cobra

### New Assembly Constructs

We will only add one new assembly construct: `Label`, of type `arg`, which
allows us to move labels into registers (i.e. placing `our_code_starts_here`
into `eax`).

As usual, full summaries of the instructions we use are at [this assembly
guide](http://www.cs.virginia.edu/~evans/cs216/guides/x86.html).

### FAQ
#### What is `well_formed_e` supposed to do?
`well_formed_e` is supposed to return a list of the static errors present in
a given expression. For this assignment, you will need to extend this to return
a list of the static errors present in an entire program.

#### What is `check` supposed to do?
`check` is supposed to `failwith` the errors present in the input program so
compilation terminates and the errors in the source code are reported.

#### What is a valid function name?
Function names follow the same rules as identifiers. It is possible for both
an identifier and function to have the same name.

### Testing Functions
Due to the changes to the syntax, which now requires `our_main` be present, we
have lost backwards compatibility for our programs. In order to make it easier
to port tests from previous assignments, we have added new test functions (with
the suffix `_main`) which will wrap the input in a valid Cobra program (namely,
by putting the expression in the body of the `our_main` definition). To use the
`_main` test functions, copy them from `test.ml` into `myTests.ml` along with
the function `wrap_prog`, and change any calls to `t`, `t_i`, etc with `t_main`,
`t_i_main`, etc. Otherwise, use the test function with suffix `_prog` to test
your complete Cobra programs.

#### Valgrind
While we allow you to implement any calling convention, we require that valgrind
passes with no reported errors. There are two methods of testing your compiler
with valgrind:

1. Running valgrind on each program individually

`valgrind ./output/####.run`

where "####" is the name of the test

2. Using `tvg` in your test suite. `tvg_i_main` behaves similarly to `t_i_main` and
`tvg_main` behaves similarly to `t_main`, where the former takes arguments while the
latter does not. For example, if we wish to run the program `foo` that takes no
`input` and returns `5`, we would write:

`tvg_main "foo" "(+ 1 4)" "5";`

#### Sample Programs
Below are some sample programs and what they should return. Hopefully this clears up
some questions about functions

```
(
  (define giveMe5 ()
    5)
  (define our_main (input)
    (giveMe5))
)
(* evaluates to 5 *)

(
  (define our_main (input)
    (add3 1 2 3))
  (define add3 (x y z)
    (+ (+ x y) z))
)
(* evaluates to 6 *)

(
  (define foo ()
    5)
  (define our_main (input)
    (let ((foo 2))
      (- (foo) foo)))
)
(* evaluates to 3 *)
```


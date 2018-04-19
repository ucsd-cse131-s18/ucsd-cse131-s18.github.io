---
layout: page
title: "PA2 – Bitwise Offset Arrangement"
---

# PA2 Boa, Due Wednesday 4/25/2018 (Open Collaboration)

![A boa](https://animalcorner.co.uk/wp-content/uploads/2015/02/boa-constrictor-1.jpg)

[Get your repo here](https://classroom.github.com/assignment-invitations/21d16e460f0d988f23eea70a169dfc56)

In this assignment you'll implement a small language called Boa, which
implementes a Bitwise Offset Arrangement of different values. It also uses C function calls to implement
some user-facing operations, like reading an input and reporting errors.

## The Boa Language

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

<bindings> :=
  | (<identifier> <expr>)
  | (<identifier> <expr>) <bindings>

```

### Abstract Syntax

The abstract syntax of Boa is an OCaml datatype, and corresponds nearly
one-to-one with the concrete syntax.

```
type prim1 =
  | Add1
  | Sub1
  | Print
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
  | EInput
  | EPrim1 of prim1 * expr
  | EPrim2 of prim2 * expr * expr
```

### Semantics

There are four main changes that ripple through the implementation:

- The representation of values
- Optional command-line input
- The addition of if/else conditionals
- Checking for errors

### Representation of Values

The representation of values requires a definition.  We'll use the following
representations for the Boa runtime:

- `true` will be represented as the constant `0xFFFFFFFE`
- `false` will be represented as the constant `0x7FFFFFFE`
- numbers will be represented with a one in the rightmost bit, with the actual two's complement
  value shifted to the left by one (as in class).
  So, for example, `2` is represented as `0x00000005`, `-5` is represented as `0xFFFFFFF7`.

If integer literals exceed the range of representable value, two types of errors should be handled:
- Unable to parse non-representable integer literal error

For example, the following Boa program
```
9999999999999999
```
should throw `Non-representable number 9999999999999999` before compilation.

- Runtime overflow error

For example, the following Boa program 
```
1073741823 + 10
```
should throw `overflow` at runtime.

## Handling Input Value

You will implement a pre-defined variable — `input`, which should evaluate to a
user-provided inputted value, which can be an integer number, true, or false. 
You need to parse the input value in `main.c` and check for two parsing errors at runtime:
1. input must be a boolean or a number
2. input is not a representable number

If an argument isn't provided to the executable, the default value of `input` should be `false`.
After the input value is parsed, it will be passed to `our_code_starts_from_here` as a function
argument that will get stored on its stack frame. To make `input` variable accessible to Boa, we add
(`input`, -1) to the program environment binding. 

The input value should be provided as a command-line argument
to the _generated executable_.

For example, `./somefile.run 4` makes it so `input` evaluates to 4.

### Checking for Errors

#### The check function

We will be asking you to write up the check function which will check your program
before compilation. We expect check to return a list of strings
containing an exact series of error messages. We will be testing against this function
so be sure to match the expected output.

The only errors you will need to check here are:

- Unbound Identifier ie. `EId` not in the scope of an `ELet`

  Error string = "Variable identifier {id name} unbound"

- Multiple Bindings ie. `ELet([("x", ENumber(2)); ("y", ENumber(5)); ("x", ENumber(5))], EId(x))`

  Error string =  " Multiple bindings for variable identifier {id name}"

Note that once an error is found, it should be added to the return string list and check
should still continue to find any other errors.

#### Error handling with assembly

We will be also asking you to handling errors during the runtime of the program. The only
errors you will need to check here are:

- `-`, `+`, `*`, `<`, and `>` should raise an error (by printing it out) with
  the substring `"expected a number"` if the operation doesn't get two numbers
  (you can print more than this if you like, but it must be a substring)
- `add1` and `sub1` should raise an error with the substring `"expected a
  number"` if the argument isn't a number
- `if` should raise an error with the substring `"expected a boolean"` if the
  conditional value is not a boolean.
- `+`, `-`, and `*` should raise an error with the substring `"overflow"` if
  the result overflows, and falls outside the range representable in 31 bits.
  The `jo` instruction (not to be confused with the Joe Instructor) which
  jumps if the last instruction overflowed, is helpful here.

These error messages should be printed on standard _error_, so use a call like:

```
fprintf(stderr, "Error: expected a number")

in the case of

if 54: true else: false

# prints (on standard error) something like:

Error: expected a boolean in if, got 54
```

I recommend raising an error by adding some fixed code to the end of your
generated code that calls into error functions you implement in `main.c`.  For
example, you might insert code like:

```
internal_error_non_number:
  push eax
  call error_non_number
```

Which will store the value in `eax` on the top of the stack, move `esp`
appropriately, and perform a jump into `error_non_number` function, which you
will write in `main.c` as a function of one argument.
If you look closely you may notice that we aren't updating ESP for our local vars but we still call another function. This overwrites the callee's stack space but is ok since we exit after printing errors. Future PAs will fix this hack.

## Implementing Boa

### New Assembly Constructs

#### Conditional Constructs

- `ILabel of string` — Create a location in the code that can be jumped to
  with `jmp`, `jne`, and other jump commands

  Example: `this_is_a_label:`

- `ICmp of arg * arg` — Compares the two arguments for equality.  Set the
  _condition code_ in the machine to track if the arguments were equal, or if
  the left was greater than or less than the right.  This information is used
  by `jne` and other conditional jump commands.

  Example: `cmp [esp-4], 0`

  Example: `cmp eax, [esp-8]`

- `IJne of string` — If the _condition code_ says that the last comparison
  (`cmp`) was given equal arguments, do nothing.  If it says that the last
  comparison was _not_ equal, immediately start executing instructions from
  the given string label (by changing the program counter).

  Example: `jne this_is_a_label`

- `IJe of string` — Like `IJne` but with the jump/no jump cases reversed

- `IJmp of string` — Unconditionally start executing instructions from the
  given label (by changing the program counter)

  Example: `jmp always_go_here`

- `Ijl of string` - Jump if the last comparison said the first value was less
  than the second. Otherwise do nothing.

- `Ijg of string` - Jump if the last comparison said the first value was greater
  than the second. Otherwise do nothing.

- `IJo of string` - Jump if the last operation set the overflow condition code,
  otherwise do nothing.

- `IJno of string` - As above, but only jump when the condition code is not set.

#### Combining `cmp` and Jumps for If

When compiling an if expression, we need to execute exactly _one_ of the
branches (and not accidentally evaluate both!).  A typical structure for doing
this is to have two labels: one for the else case and one for the end of the
if expression.  So the compiled shape may look like:

```
  cmp eax, 0    ; check if eax is equal to 0
  je else_branch
  ; commands for then branch go here
  jmp end_of_if
else_branch:
  ; commands for else branch go here
end_of_if:
```

Note that if we did _not_ put `jmp end_of_if` after the commands for the then
branch, control would continue and evaluate the else branch as well.  So we
need to make sure we skip over the else branch by unconditionally jumping to
`end_of_if`.

#### Creating New Names on the Fly

When creating labels, we can't simply use the same identifier
names and label names over and over.  The assembler will get confused if we
have nested `if` expressions, because it won't know which `end_of_if` to `jmp`
to, for example.  So we need some way of generating new names that we know
won't conflict.

You've been provided with a function `gen_temp` (meaning “generate
temporary”) that takes a string and appends the value of a counter to it,
which increases on each call.  You can use `gen_temp` to create fresh names
for labels and variables, and be guaranteed the names won't overlap as long as
you use base strings don't have numbers at the end.

For example, when compiling an `if` expression, you might call `gen_temp`
twice, once for the `else_branch` label, and once for the `end_of_if` label.
This would produce output more like:

```
  cmp eax, 0    ; check if eax is equal to 0
  je else_branch1
  ; commands for then branch go here
  jmp end_of_if2
else_branch1:
  ; commands for else branch go here
end_of_if2:
```

And if there were a _nested_ if expression, it might have labels like
`else_branch3` and `end_of_if4`.

### Other Constructs

- `Sized`

    You may run into errors that report that the _size_ of an operation is
    ambiguous.  This could happen if you write, for example:

    ```
    cmp [ebp-8], 0
    ```

    Because the assembler doesn't know if the program should move a four-byte
    zero, a one-byte zero, or something in between into memory starting at
    `[ebp-8]`.  To solve this, you can supply a size:

    ```
    cmp [ebp-8], DWORD 0
    ```

    This tells the assembler to use the “double word” size for 0, which
    corresponds to 32 bits.  A `WORD` corresponds to 16 bits, and a `BYTE`
    corresponds to 16 bits.  To get a sized argument, you can use the `Sized`
    constructor from `arg`.

- `HexConst`

    Sometimes it's nice to read things in hex notation as opposed to decimal
    constants.  I've provided a new `HexConst` `arg` that's useful for this
    case.

- `IPush`, `IPop`

    These two instructions manage values on the stack.  `push` adds a value at
    the current location of `esp`, and increments `esp` to point past the
    added value.  `pop` decrements `esp` and moves the value at the location
    `esp` was pointing to into the provided arg.

- `ICall`

    A call does two things:

      - Pushes the next _code_ location onto the stack (just like a `push`),
        which becomes the return pointer
      - Performs an unconditional `jmp` to the provided label

    `call` does not affect `ebp`, which the program must maintain on its own.

- `IShr`, `ISar`, `IShl`: Bit shifting operations

- `IAnd`, `IOr`, `IXor`: Bit masking operations

- `near`: Perform a near jump rather than the default short jump. The default short
  jump is too close to be useful during compilation. We have already
  filled out jump instructions so you don't need to worry about 
  "short jump out of range" error. 

As usual, full summaries of the instructions we use are at [this assembly
guide](http://www.cs.virginia.edu/~evans/cs216/guides/x86.html).

### Printing Tagged Value in C
When Boa returns, it saves the return value in register EAX. In C, return value goes into EAX
by convention. To print the return value, you need to fill out `print` function. Since values
are tagged in Boa, you need to do bitwise manipulations before using printf.

For example, if the return value is `0xFFFFFFFE` or 0x7FFFFFFE, you should print `true\n` or `false\n`. 
If the return value is a `0xFFFFFFF7`, you should print `-5\n`.
Otherwise print the value in using this printf format `Unknown value: %#010x\n`.

### FAQ
#### What is well_formed_e supposed to do?
`well_formed_e is` supposed to return a list of static errors from your source program found during compilation.

#### What is check supposed to do?
`check` is meant to failwith the errors gathered in `well_formed_e` so compilation terminates and you can see what errors your source program had.

#### What is a valid id name?
You can assume that an id is a valid string of form [a-zA-z][a-zA-Z0-9]*. You will, however, have to check that the string does not match any of the language's reserved words.

### Testing Functions

These are the same as they were for Anaconda.  Your tests should
focus on `t` tests. In addition, to test command-line argument, 
you can call `t_i`. To test command-line argument parsing errors,
use `terr_i`. To test parser, use `t_parse`. 

An old friend is helpful here, too: `gdb` (or `lldb` on Mac OSX). 
You can run `gdb output/some_test.run` in order to get a little more feedback
on tests that fail with `-10` as their exit code (which usually indicates a
segfault).  This can sometimes tip you off quite well as to how memory is off,
since sometimes you'll see code trying to jump to a constant that's in your
code, or other information about the specific instruction that fails.
You can use `set disassembly-flavor intel` to have gdb display assembly in the
intel syntax we use, and otherwise debug assembly as usual in gdb.

---
layout: page
title: "PA8 – Garter"
doodle: "https://upload.wikimedia.org/wikipedia/commons/thumb/b/b7/Sharp-Nosed_Viper_01.jpg/1920px-Sharp-Nosed_Viper_01.jpg"
---

> The popular name “hundred pacer” refers to a local belief that,
> after being bitten, the victim will only be able to walk 100 steps
> before dying.

# PA8 - Hundred Pacer (Open Collaboration)

It is due by 11:59pm on Thursday, June 7th.

This compiler tries to run in as few steps as possible – programs
may be able to finish “within 100 paces”.

GitHub Classroom Link: [https://classroom.github.com/a/mSI2tEND](https://classroom.github.com/a/mSI2tEND)

## Language

The language is identical to Garter. To compile input programs, use the usual commands:

```
./main path/to/file.hundred   # to see the instructions output directly on stdout
make output/file.run          # to get the executable corresponding to file.hundred in input/
make output/file.s            # to get the assembly file corresponding to file.hundred in input/
```

## Implementation

In this last programming assignment, you will be implementing a series of optimizations that improve programs by reducuing the number of assembly instructions generated. The three optimizations you are required to implement are:

- Constant propagation
- Constant folding
- Instruction selection

Beyond these three, you are free to implement any other optimizations as long as the resulting program still returns the same answer and has the same effects as the original (unoptimized) program. The only exception to this is that you are allowed to find ways to use _less memory_ than the original program (either through saving stack space OR saving heap space). So a program that overflows the stack or runs out of heap space on the original is allowed to produce an answer if space was the only reason the program crashed.

### Constant Folding

Instead of generating instructions to evaluate binary operations between number constants or boolean constants at runtime, we can evaluate the expressions at compile time.

Example 1: 

By explicitly matching on any plus operations applied to two numbers, we can directly compute the expected result. 

``` 
...
match e with 
  | EPrim2(Plus, ENumber(n1), ENumber(n2)) -> ENumber(n1+n2)
...
```

Original Version - 
```
(let ((x (+ 5 6)) (y (< 7 8))) (if y x false))
```

Optimized Version - 
```
(let ((x 11) (y true)) (if y x false)))
```

After constant folding, the resulting program will have evaluated all of the expressions in the binding list. To see the runtime effects of such a change, you can put a simple arithmtic operation
in a large loop, and verify that your optimizations speeds the program up.

### Constant Propagation


Example 1: 

We can transform the below expression by substituting the value of x into the body of the ELet and returning the simplified expression.

```
match e with 
	| ELet((x, ENum(n))::binds, body) -> replace body x (ENum(n)) 
``` 

Original Version -  
````
(let ((x 11)) (+ x 3)) 
````

Optimized Version -  
```
(+ 11 3)
```

Constant folding and constant propagation are most useful when run together. We can execute one round of constant folding, followed by a round of constant propagation, and then repeat until the program no longer changes (it reaches a **fixpoint**).

Let's see how this works:

```
(let ((x (+ 5 6)) (y (- 8 7))) (+ x y))
```

=> constant folding =>

```
(let ((x 11) (y 1)) (+ x y))
```

=> constant propagation =>

```
(+ 11 1)
```

=> constant folding =>

```
12 
```

At this point, if we run constant folding and constant propagation again, we'll get the same program -- there are no more constants to propagate or constant operations to fold.

### Instruction Selection

We can also be smart about which instructions we choose to generate within the context of specific expressions. 

Example 1: 

```
match e with 
	| EIf(EPrim2(Greater, e1, e2), then_expr,else_expr) -> 
		(* Compile e1 and e2, and true or false stored in EAX *)
		(* We can skip the boolean check since we know that if_expr is either true or false*)
```

As was discussed in lecture, if the expression in the conditional for an `if` statement is an operation that is known to produce a boolean value, then we can forego the additional instructions that perform a boolean check. 

We can also optimize further and use the result of `if_expr` to decide which branch we will jump to!


Think about what other cases you can potentially optimize! 

### Starter Code

We have given you `constProp.ml` to fill in as an example, currently it does nothing. The function `c_prop` will take in an AST which is the body of each function. In propogating constants, we want to identify values from bound identifiers in an ELet expression and replace any identifiers in the body with the constant value. 

Function definition for c_prop: 

`let c_prop (ast : expr) : expr =`

We can use a helper function `replace` to substitute the values for any identifiers in the expression. 

`let replace (e : expr) (id : string) (value : expr) =`


We have given you `optimize.ml`, you can add any optimization functions you have written to the transforms list in order to run them in a loop until we reach a fixpoint (examples: `constProp` and `constFold`). Other optimizations that will likely only be applied once, like function inlining (an optional optimization described below), can be applied before the the recursive call to optimize.

The changes you make for instruction selection can be made simply by adding new match cases and conditions to the compiler itself.

### Extra Optimizations

There are other interesting optimizations you might consider if you have time, but we won't be grading for these explicitly.

#### Function Inlining 

We can also decrease the runtime overhead of calling and returning from multiple functions by replacing function calls with the body of the function. 

Example 1: 

```
((define f() (tup 1 2))
(define our_main(input) (tup (f) (f))))
``` 

After inlining the function f:  

```
((define f() (tup 1 2))
(define our_main(input) (tup (tup 1 2) (tup 1 2))))
``` 

What about functions with arguments? We would have to first bind the functions arguments to the formal parameters before replacing the call site of the function with the function body. 

```
((define f(x, y) (tup x y))
(define our_main(input) 
  (tup (f 1 2) (f 3 4))))
``` 

After inlining the function f:  

```
((define f(x, y) (tup x y))
(define our_main(input) 
  (tup (let ((x 1) (y 2)) (tup x y)) (let ((x 3) (y 4)) (tup x y))))
```

With this new set of bindings, we now enable using constant propogation and constant folding to simplify the body.

There are certain functions that we shouldn't attempt to inline (like recursive functions). 
As a second note, inlining will very likely increase code sizes due to increased duplication.

To test this, it is again possible to place a function call in a large loop, and verify the speedup due to the function overhead being gone.

#### Register Allocation

As was discussed in lecture, we can also store values in registers rather than directly storing all values on the stack.

All programs will first go through an ANF transformation so any non-trivial expressions will be bound to a variable. An implementation of ANF transformation is provided in `anf.ml` for your use should you decide to implement register allocation. Make sure that you transform the input program to ANF form before attempting to compile it with register allocation implemented.

We will want to create a graph where the vertices will represent the variables in the program and the edges will be dependencies; vertices will be connected when both variables must be available at the same time. Then, we can figure out the optimal assignments given a graph to create an environment of variables to registers available. Since variables will now be stored in registers as well, this will require changes to our compiler's `env` parameter: variable identifiers can be mapped to stack offsets or registers now. 

You can use the library ([ocamlgraph](http://ocamlgraph.lri.fr/index.en.html) for graph coloring and to determine a register for each vertex. It will be helpful to look at a few examples that use ocamlgraph to solve other problems: http://ocamlgraph.lri.fr/sudoku.ml. The additional registers we have to work with include: `EDI`, `ESI`, `EDX`, `ECX`.


Only after implementing the other optimizations should you attempt register allocation, it will not be required. 

### Testing

Your optimizations will be graded by running them on several programs that we provide, and checking how much they improve in instruction count and/or runtime. We'll release more specific descriptions along with the grader.

You can get started now by running `make` to build the `main` executable. We have provided a compiler at `compilers/no-opt` which does not perform any optimizations.

You can use `wc -l output/file.s` to get the number of assembly instructions (lines) in `output/file.s`. To test your optimizations, compile your test program unoptimized using the public compiler, and compile the same program optimized using your compiler, and compare the number of lines using `wc -l`:

```
> ./compilers/no-opt input/file.hundred > output/file.s
> ./main input/file.hundred > output/file.opt.s
> wc -l output/file.s
> wc -l output/file.opt.s
```

Since this could get tedious, we have provided you with a useful shell script `testOpt.sh` that, given a filename, will compile and assemble both optimized and unoptimized versions and compare their instruction counts and runtimes.

When writing test programs, you should be sure to consider at least the following types of programs (this is not a comprehensive list!):

- Programs that do arithmetic in loops
- The BST and list style programs that we wrote in PA4
- Programs that do lots of tuple allocation and access

Your optimized program MUST be equivalent to the non-optimized program, or else it will not be
considered to work. 

In order to test your programs, it may also be helpful to add a print statement that
prints out the AST at different stages in your optimization pipeline. The provided
`string_of_program`, `string_of_function`, and `string_of_expr` functions in `expr.ml`
should aid in this.

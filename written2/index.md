---
layout: page
title: "Written Assignment 2"
doodle: "../doodle.png"
---

# Written Assignment 2 (closed collaboration)

No matter how you continue in the field of computer science—whether you're a
software engineer, academic researcher, web developer, systems architect,
technical writer, etc—you will be confronted with numerous design decisions.
That is, you or someone on your team will have an idea for how to improve the
status quo, or how to get off the ground on a new project that you're not
sure how to start, and so on. You will need to develop skills in effectively
judging the merit of these ideas, and communicating it to your team or to
other groups.

In addition, lots of modern language design happens in Github issues, mailing
lists, and with carefully-written proposals on project Wiki pages. Making
your argument clear and using examples allows others to critique it
effectively and iterate on designs.

These skills are what these assignments seek to simulate (along with
evaluating your understanding of compilers). Each poses a design question.
Approach your answer as if you are writing a technical email to your peers or
colleagues, and need to explain the reasons for different decisions and how
they are made. These communications should be:

- Unambiguous, so that everyone knows what you mean (whether you are right or wrong).
- Descriptive, so that readers have examples or other concrete aspects of the
answer to respond to.
- Technically accurate, so that any assumptions made are explicit, and the
the resulting chain of reasoning is clear
- Concise, so that people don't have to waste time wading through extra words

You'll be graded on all these things (concision we enforce by giving you
length limits, and more per-question grade criteria are provided
below), so “wrong” answers can get significant credit if they are clear
enough that the mistake is understandable. The point is to have made
identifiable decisions with plausible justification and a concrete
specification.

## Strings

Come up with a design and implementation plan for adding ASCII strings to
Diamondback. Consider:

- Changes to concrete syntax
- Changes to abstract syntax
- What new expressions or operators will be needed to work with strings
- What representation strings will have at runtime
- How this will interact with existing features and values from Diamondback

Make sure that your implementation can support at least:

- Concatenating two strings
- Getting the length of a string
- Creating a new string that's a substring of an existing string

## Variable-Arity Functions

Many languages support _variable-arity_ functions that can be called with many
different numbers of arguments, bundling together the extra arguments into a
data structure (note that this is distinct from _overloading_). For example, in
Python, an asterisk before the final argument indicates that it will hold all
additional arguments that are provided. If too few arguments are provided, it
is still an error. For example (you can run this by saving it to a file and
running `python` on that file; you're encouraged to do this and write more
tests to think about the behavior!):

```
def f(x, *y):
  return y

print(f(1, 2, 3))  # (2, 3) is bound to y

print

print(f(1))   # an empty tuple is bound to y

print

print(f())    # an arity error
```

Design and describe an implementation plan for adding variable arity functions
to Diamondback. Assume that the function _declaration_ uses a special keyword,
`define*`, to indicate that it is variable-arity. For example, the following
program should evaluate to the tuple value `(2,3)`:

```
(
(define* f (x y) y)
(define our_main (input)
  (f 1 2 3))
)
```

- Changes to concrete syntax
- Changes to abstract syntax
- New runtime representations (if any)
- New or changed errors (if any)
- How to compile `define*` functions
- Any changes to compiling function calls

## Common Subexpression Elimination

In class, we discussed constant propagation: an optimization that substitutes
constants into other expressions to save on variable space.

A related optimization is called common subexpression elimination. In some
ways, it's the dual of constant propagation.

It works like this: In an expression, search for multiple instances of the same
sub-expression, and replace them with a new variable. Then wrap the whole
expression in a new let binding for that variable that computes the expression.
We can do this on, say, each function body to avoid repeated computation.

So, for example, we might change:

```
(define dist (x1 x2 y1 y2)
  (sqrt (+ (* (- x1 x2) (- x1 x2)) (* (- y1 y2) (- y1 y2)))))
```
into:

```
(define dist (x1 x2 y1 y2)
  (sqrt (+
    (let ((tmp1 (- x1 x2))) (* tmp1 tmp1))
    (let ((tmp2 (- y1 y2))) (* tmp2 tmp2)))))
```

The common sub-expressions were `(x1 - x2)` and `(y1 - y2)`. The idea is to
avoid repeating the same computation – in the optimized program, the
subtraction only needs to happen twice, rather than four times.

Some expressions, if eliminated in this way, clearly change the meaning of the
program. print expressions are an obvious example. It would change the program
to turn:

```
(define f (x)
  (tup (print x) (print x)))
```
into

```
(define f (x)
  (let ((tmp (print x)))
    (tup tmp tmp)))
```

In fact, a slight change to the first optimization could change the first
program, too, but more subtly. Consider this rewrite:

```
(define dist (x1 x2 y1 y2)
  (let ((tmp1 (- x1 x2))
        (tmp2 (- y1 y2)))
    (sqrt (+ (* tmp1 tmp1) (* tmp2 tmp2)))))
```

Consider a call to `dist` where the quantity `(- x1 x2)` is large enough to
overflow when multiplied by itself, and `y1` is mistakenly passed as a boolean.
In the first program, the overflow error would result. In the second, the
not-a-boolean error would result. It was critical that the new temporary
variables were inserted precisely where they were.

Answer the questions below.  For this problem, assume that CSE applies only
when the same operator expression appears more than once in a function body,
and only to operator expressions that have booleans, numbers, and identifiers
as operands.

- Are there principled changes to the language we could make that would make it
  easier to not change the program's behavior with this optimization? Hint:
  Think about C's rules for arithmetic, equality, and the first question from
  the first written assignment. If so, what are they and why? If not, why not?

- Are there principled changes to our working definition of “acceptable
  optimization” that would make it easier to apply CSE? If so, what are they
  and why? If not, why not?

- If we were to run common subexpression elimination in a fixpoint loop with
  constant propagation and constant folding, would the loop terminate for all
  programs? Argue convincingly for why it would terminate, or give an example
  of a program that would cause the combined optimizations to not terminate.

## Turnin

You must turn in a PDF for your submission on Gradescope to the `written2`
assignment. Each answer should fit within 2 pages, for a total of 6 pages or
less. The assignment is due by 11:59pm on Tuesday, June 5.


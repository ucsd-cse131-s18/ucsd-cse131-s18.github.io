---
layout: page
title: "PA0 – OCaml and Compiler Warmup"
doodle: "../doodle.png"
---

# PA0 – OCaml and Compiler Warmup

This assignment has two goals:

- You will get a lot of practice writing OCaml programs
- You will write an _extremely_ simple compiler (for numbers)

It interleaves explanation with the assignment itself. You will complete all
the listed **Exercises** in the file `functions.ml` and test them in `test.ml`
for the OCaml portion, and you will also create a few files in the `compiler/`
directory for the compiler.

You should hand everything in on  _Wednesday, April 11_ by 11:59PM.

[OCaml Basics](#ocaml-basics) – [A First Compiler](#neonate)

<a id="ai"></a>
## Academic Integrity and This Assignment

This assignment is an **open collaboration** assignment. Consult the [policies
section](/#policies) of the home page for a description of what that means.

<a id="ocaml-basics"></a>
## OCaml Basics

We will use three programming languages in this course: OCaml, C (not C++), and
x86 assembly.  The parts of x86 we use will be sufficiently straightforward
that the differences between it and whatever you learned in the equivalent of
CSE30 will be minor.  Most of you should have some background in programming in
a functional style, which is predominantly how we'll use OCaml.


## Setup

OCaml is installed on the ACMS machines; you can go to
[the ETS Page](https://sdacs.ucsd.edu/~icc/index.php) to get your
account.  You need to do a small bit of setup to use some libraries we'll need
for the course.  Open up the file `.bashrc` in your home directory (with
e.g. `vim ~/.bashrc`), and add these lines at the bottom:

```
eval `opam config env --root=/home/linux/ieng6/cs131s/public/`
. /home/linux/ieng6/cs131s/public/opam-init/init.sh
```

Then run:

```
$ source ~/.bashrc
```

Also append the following to your `.bash_profile` file as well:
```
if [ -f ~/.bashrc ]; then
    source ~/.bashrc
fi
```

This makes it so each time you open a terminal, the build commands you run for
OCaml will be able to use some libraries we need for the course.

### Other Platform Instructions

If you want to work on your own machine, you can install OCaml and OPAM via
their platform-specific instructions.  Everything in the course should be able
to run on Windows and OSX as long as the machine has the x86 architecture.

In order to run the code we use in the course, you will need to run

```
$ opam install extlib ounit ocamlfind
```

### Github & Gradescope

Assignments this semester will be distributed through Github Classroom and
submitted through Gradescope.  This first assignment is to be done
independently.  This Piazza post has link to get a Github clone of the
assignment to work with (you will sign up to Github Classroom if you haven't
already):

https://classroom.github.com/a/W5Ow7S0t

To submit, you can use the “Github” option in Gradescope's submission
interface. **We will make Gradescope submission available on Thursday, April
5**

## Programming in OCaml – The Basics

This section covers some basics first, and then gives a structured
introduction to how we'll program in OCaml in this course.

### The Simplest Program

OCaml files are written with a `.ml` extension.  An OCaml file is somewhat
similar to a Python file: when run, it evaluates the file directly (unlike,
for example, C++, which designates a special `main` function).
An OCaml file consists of

- (Optionally) a series of `open` statements for including other modules
- A series of declarations for defining datatypes, functions, and
  constants.
- A series of (though often just one) toplevel expressions to evaluate.

For example:

```
open Printf

let message = "Hello world";;
(printf "%s\n" message)
```

The first line includes the built-in library for printing, which provides
functions similar to `fprintf` and `printf` from `stdlib` in C.  The
next two lines define a constant named `message`, and then call the
`printf` function with a format string (where `%s` means “format as
string”), and the constant `message` we defined on the line before. 

Put this in a file called `hello.ml` and run it with:

```
$ ocaml hello.ml
Hello world
```

Most of our programs will be more complex than this, and much of the
infrastructure for the “main” function will be provided, but it's useful to
see the simplest case first.

### Defining and Calling Functions

One thing that we'll do over and over again is define functions.  Here's an
example of a function definition in OCaml:

```
let max (n : int) (m : int) : int =
  if n > m then n else m;;
```

It uses the keyword `let` followed by the name of the function (here,
`max`).  Next comes the parameter list.  Each parameter is enclosed in
parentheses, and has the parameter's name, then a colon, then its type.  So
`n` and `m` are the parameters of `max`, and they are both type
`int`.  The final colon followed by `int` describes the return type of
the function.  Then there is an `=` sign, followed by the function body.

This declaration is similar to the following in C++:

```
int max(int n, int m) {
  if(n > m) { return n; }
  else { return m; }
}
```

One notable difference is that the OCaml function does not have any
`return` statements.  We'll talk about how to think about the “return”
value of a function without `return` statements next.  It's also important
to note that the declaration in OCaml ends in `;;`.  This is a required
syntactic convention for all top-level declarations in OCaml.

(We'll get to a more robust notion of testing in a little bit.)
We can check that `max` works by defining a useful top-level call with
print statements:

```
open Printf

let max (n : int) (m : int) : int =
  if n > m then n else m;;

(printf "Should be 5: %d\n" (max 5 4));
(printf "Should be 4: %d\n" (max 3 4));
(printf "Should be 4: %d\n" (max 4 4));
```

You can copy this program into a file called `max.ml` and run it with
`ocaml max.ml`.

There are a few things to explain here.  First, the syntax for function calls
in OCaml is different than you may be used to.  Instead of writing

```
some_function(arg1, arg2, ...)

// for example

max(4, 5)
```

as we would in C++ or Python, in OCaml we write

```
(some_function arg1 arg2 ...)

// for example

(max 4 5)
```

(The surrounding parentheses can be omitted in some cases, but it's
always safe to include them to be clear.)

There's also a useful distinction in how I prefer to think about what happens
when we call a function in OCaml.  Rather than thinking about a call to `max`
creating a new stack frame, let's think about what happens if we
_substitute_ the provided argument values for the parameters in the body
of `max`, and continue by evaluating the function body.  This notion of
substitution is “just” a useful model; everything you know about stacks and
memory diagrams is still true (and in fact, we'll talk about stacks in quite a
bit of detail this quarter).  But substitution is a very helpful model for
reasoning in the style of programming we'll do.

So, for example, the call to `max` below _takes a step_ to the
substituted form:

```
   (max 4 5)

=> if 4 > 5 then 4 else 5
```

Then we can think about how the `if` expression takes steps.  First, it
evaluates the conditional part, and based on that value being `true` or
`false`, it evaluates one or the other branch:

```
   if 4 > 5 then 4 else 5

=> if false then 4 else 5

=> 5
```

From this sequence of steps, we say that `(max 4 5)` _evaluates to_
`5`.  This gives us a way to think about evaluation that doesn't require a
notion of a `return` statement.

With this idea of substitution in mind, we can think about how the sequence of
`printf` expressions we wrote will evaluate:

```
  (printf "Should be 5: %d\n" (max 5 4));
  (printf "Should be 4: %d\n" (max 3 4));
  (printf "Should be 4: %d\n" (max 4 4));

=> (printf "Should be 5: %d\n" (if 5 > 4 then 5 else 4));
   (printf "Should be 4: %d\n" (max 3 4));
   (printf "Should be 4: %d\n" (max 4 4));

=> (printf "Should be 5: %d\n" (if true then 5 else 4));
   (printf "Should be 4: %d\n" (max 3 4));
   (printf "Should be 4: %d\n" (max 4 4));

=> (printf "Should be 5: %d\n" 5);
   (printf "Should be 4: %d\n" (max 3 4));
   (printf "Should be 4: %d\n" (max 4 4));
```

(The rule for semicolon-separated sequences is that they are evaluated in
order, and the value resulting from each expression is ignored once it is
done.)

```
=> <internal-to-OCaml-printing of "Should be 5: 5\n">;
   (printf "Should be 4: %d\n" (max 3 4));
   (printf "Should be 4: %d\n" (max 4 4));

=> (printf "Should be 4: %d\n" (max 3 4));
   (printf "Should be 4: %d\n" (max 4 4));

=> (printf "Should be 4: %d\n" (if 3 > 4 then 3 else 4));
   (printf "Should be 4: %d\n" (max 4 4));

=> (printf "Should be 4: %d\n" (if false then 3 else 4));
   (printf "Should be 4: %d\n" (max 4 4));

=> (printf "Should be 4: %d\n" 4);
   (printf "Should be 4: %d\n" (max 4 4));

=> <internal-to-OCaml-printing of "Should be 4: 4\n">;
   (printf "Should be 4: %d\n" (max 4 4));

... and so on
```

### Recursive Functions

A lot of the code we write this semester will be recursive
functions.  OCaml distinguishes between functions that can contain recursive
calls and functions that cannot.  We saw the latter kind above in `max`
which simply used the `let` keyword.  We can define a recursive function by
using `let rec`:

```
let rec factorial (n : int) : int =
  if n <= 1 then 1
  else n * (factorial (n - 1));;
```

The substitution-based rules are a little more interesting when thinking about
evaluating a call to `factorial`:

```
  (factorial 3)

=> (if 3 <= 1 then 1 else 3 * (factorial (3 - 1)))

=> (if false then 1 else 3 * (factorial (3 - 1)))

=> (3 * (factorial (3 - 1)))

=> (3 * (factorial 2))

=> (3 * (if 2 <= 1 then 1 else 2 * (factorial (2 - 1)))

...

=> (3 * (2 * (factorial (2 - 1))))

...

=> (3 * (2 * 1))

=> 6
```

Here, we can see the chained multiplications “stack up” during the recursive
calls.  Writing this in a substitution-based style makes it easy to track
where the return values of function calls end up.

### Testing with OUnit

Testing by printing values becomes pretty onerous when we want to write more
than a few examples.  In this course, we'll use a library called
(OUnit)[http://ounit.forge.ocamlcore.org/api-ounit/index.html] to write tests.

With OUnit, we will write declarations in one file, and test them in another.
The code provided in your checkout has two files: `functions.ml`, which
you'll fill in with some implementations in the rest of the exercises, and
`test.ml`, which will contain tests.  This will become a common layout for
how we write our programs in this course.

A test in OUnit is a name paired with a function of one argument.  The function
uses one of several different test predicates to check a computation—the one
we'll use most commonly is `assert_equal`.  The syntax `>::` is used to combine
the name and the function together into a test.  (The weird-looking `>::`
operator is described (here)[http://ounit.forge.ocamlcore.org/api-ounit/OUnit2.html#VAL(>:::)]
in terms of more basic concepts, if you're interested.  It's just a shorthand
for constructing a test value with a name.) Here's an example:

```
open OUnit2
let check_fun _ = (* a function of one argument *)
  assert_equal (2 + 2) 4;;

let my_first_test = "my_first_test">::check_fun;;
```

(Most of this is just boilerplate that you won't have to think much, if
at all, about.  But it's useful to explain it once.) Now `my_first_test` is
a named test value.  Note that we used an underscore when defining the
parameter of `check_fun`; we can use an underscore to indicate to OCaml
that we don't care about the argument (there needs to be a parameter because
of how the testing library works, even though we won't use the parameter).  We
can run our test by creating a suite out of a list of tests, and running the
suite:

```
let suite = "suite">:::[my_first_test];;
run_test_tt_main suite
```

To build and run the given skeleton, use the provided Makefile that does the
work of building for you.  In this case, you just need to run

```
$ make test
$ ./test
```

in order to run the tests. (The command used is not `ocaml` in this case,
but a wrapper around `ocaml` called `ocamlfind` that knows how to search
your system for packages installed with e.g. OPAM. Candidly, OCaml's build
system can be a little onerous, so I'm not teaching it explicitly.  If you
want to use OCaml for a large project outside this course, I recommend
learning about the `corebuild` tool that comes with Real World OCaml.)

We can also add tests that fail to see what happens:

```
let check_fun2 _ = (* a failing test *)
  assert_equal (2 + 2) 5;;

let my_second_test = "my_second_test">::check_fun2;;
```

If we add this test to the suite and run, we get a failure:

```
$ ./test
.F
==============================================================================
Error: suite:1:my_second_test.

File "/Users/joe/.../oUnit-suite-prob#02.log", line 2, characters 1-1:
Error: suite:1:my_second_test (in the log).

Raised at file "src/oUnitAssert.ml", line 45, characters 8-27
Called from file "src/oUnitRunner.ml", line 46, characters 13-26

not equal
------------------------------------------------------------------------------
Ran: 2 tests in: 0.14 seconds.
FAILED: Cases: 2 Tried: 2 Errors: 0 Failures: 1 Skip:  0 Todo: 0 Timeouts: 0.
```

This output identifies the failing test by name (my_second_test), though it
doesn't tell us much more than that.  Another annoying thing about the way we
wrote those tests is that defining a new function for every test causes
significant extra typing.  To get a little more information out, we can pass
`assert_equal` an optional argument that specifies how to turn the values
under test into a string for printing.  We can bundle that up inside a
function that creates the test with its name.  So, for example, we can define
a function that creates tests comparing integers to integers:

```
let t_int name value expected = name>::
  (fun _ -> assert_equal expected value ~printer:string_of_int);;

let my_third_test = t_int "my_third_test" (2 + 2) 7;;
let my_fourth_test = t_int "my_fourth_test" (2 + 2) 4;;
```

If we add these two tests to the suite, we see a much more useful failure
report that says `expected: 7 but got: 4`.  I'll often provide useful
helper functions for testing with examples, but you may also decide to write
your own for different kinds of tests as the semester goes on.


### Exercises

1. Implement `fibonacci` as an OCaml function that takes an integer
`n` and returns the nth fibonacci number.  Write out the evaluation of
`(fibonacci 4)` in substitution style.

2. Write tests for `min` and `fibonacci` using `t_int`.

## Programming in OCaml — Datatypes

Programming with only integers, we wouldn't make much progress on building a
compiler.  The next thing we need to do is understand how to create new
_datatypes_ in OCaml, and program with them.

### Binary Trees with `type`

Let's start with a datatype we all ought to know well—binary trees.  We
know we'll need to represent a binary tree node somehow, which has a value and
two children.  For now, let's say the value has to be a string.  In OCaml, we
can define such a node using the keyword `type`:

```
type btnode =
  | Leaf
  | Node of string * btnode * btnode
```

Translated into English, this reads:

> A binary tree node is either a _leaf_ of the tree, which has no fields, or a
> _node_, which has three fields: a string, a binary tree node, and another
> binary tree node.

This defines what we call _constructors_ for `Leaf` and `Node`,
which we can use to construct trees.  Here are a few examples of trees and
their corresponding `btnode` value:

```
    "a"       Node("a",
   /   \        Node("b", Leaf, Leaf), Node("c", Leaf, Leaf))
"b"     "c"
```

```
    "a"       Node("a",
   /            Node("b", Leaf, Leaf), Leaf)
"b"        
```

```
    "a"       Node("a",
   /            Node("b",
"b"               Leaf, Node("c", Leaf, Leaf)), Leaf)
   \
    "c"
```

Each position with no child corresponds to a `Leaf`, and the others correspond
to uses of `Node`.  We call `Leaf` and `Node` _variants_ of the `btnode`
_type_. ( A `Leaf` is used here where you may have seen `NULL` or `null` in a
C++ or Java implementation of a binary tree.)

### Manipulating Data with `match`

The next question is how to work with these values.  For example, how can we
construct an in-order concatenation of the strings in a `btnode` as we've
defined it?  That is, how do we fill in this function:

```
let rec inorder_str (btn : btnode) : string =
  ...
```

The next feature we need to introduce is `match`, which allows us to
examine which variant of a type a particular value has, and extract the values
of its fields.  Here are some examples:

```
let m1 = match Leaf with
  | Leaf -> true
  | Node(s, left, right) -> false;;

(* m1 is true *)

let m2 = match Leaf with
  | Leaf -> 44
  | Node(s, left, right) -> 99;;

(* m2 is 44 *)

let m3 = match Node("a", Leaf, Leaf) with
  | Leaf -> "z"
  | Node(s, left, right) -> s;;

(* m3 is "a" *)

let m4 = match Node("a", Node("b", Leaf, Leaf), Leaf) with
  | Leaf -> "z"
  | Node(s, left, right) ->
    match left with
      | Leaf -> "y"
      | Node(s2, left2, right2) -> s2;;

(* m4 is "b" *)
```

From these examples, we can see how `match` must work.  It inspects the
value after the `match` keyword, and selects the branch that corresponds to
the variant of that value.  Then it extracts the fields from the value, and
substitutes them for the names given in the branch.  Let's use the `m4`
example to make that concrete:

```
  match Node("a", Node("b", Leaf, Leaf), Leaf) with
    | Leaf -> "z"
    | Node(s, left, right) ->
      match left with
        | Leaf -> "y"
        | Node(s2, left2, right2) -> s2

(* substitute Node("b", Leaf, Leaf) for left *)

=> match Node("b", Leaf, Leaf) with
     | Leaf -> "y"
     | Node(s2, left2, right2) -> s2

(* substitute "b" for s2 *)

=> "b"
```

With `match` available, we can now fill in the body for `inorder_str`.
We can start by writing out a skeleton of the match structure for a
`btnode`, as most functions over `btnode`s will need to `match` on
the node to decide what to do.

```
let rec inorder_str (bt : btnode) : string =
  match bt with
    | Leaf -> ...
    | Node(s, left, right) -> ...
```

Now we can ask what the preorder traversal should yield in the case of a leaf
of the tree (or an empty tree altogether).  In this case, that ought to be an
empty string.  So the `Leaf` case should be filled in with `""`.  How
about for `Node`s?  We know an inorder traversal should have the elements
to the left in order, then the current node, then the elements to the right.
We can get the elements to either side via a recursive call, and then we just
need one more piece of information, which is that `^` is the operator for
concatenating strings in OCaml:

```
let rec inorder_str (bt : btnode) : string =
  match bt with
    | Leaf -> ""
    | Node(s, left, right) ->
      (inorder_str left) ^ s ^ (inorder_str right)
```


### Exercises

1. Write a test function `t_string`
  that's like `t_int`, but tests for equality of strings.  Can you write a
  function that produces a string form of the results like `t_int` did for
  integers? (This is a trick question.)

2.  Write at least five interesting tests for `inorder_str`.

3.  Write out the substitution-based evaluation of `inorder_str` on a
  tree with at least 3 nodes.

4.  Write a function `size` that takes a `btnode` and produces an
  integer that is the number of `Node`s in the tree.

5.  Write a function `height` that takes a `btnode` and produces an
  integer that is the height of the tree.

6.  Make sure to test the above two functions.


## Programming in OCaml — Lists and Parametric Polymorphism

### Linked Lists, By Hand

Since we've seen binary trees, it's natural to think about a similar
definition for the nodes of a linked list.  One OCaml datatype we could write
is:

```
type llist =
  | Empty
  | Link of string * llist
```

That is, a list is either `Empty` (the end of the list), or a `Link` of
a string onto another list.  Of course, this would require that we write
additional datatype declarations for lists of numbers, lists of booleans,
lists of binary trees, and so on, if we needed those shapes of data.  The
natural solution is to make the datatype generic over the kind of data it
uses.  OCaml lets us do this by defining datatypes with _type variables_
that can be filled with any type.  Type variables are written with a leading
`'` character:

```
type 'a llist =
  | Empty
  | Link of 'a * 'a llist
```

The types of the fields in `Link` have changed with this addition.  The
first field can now hold a value of the list's type, and the second must hold
a `llist` that contains elements of that type as well.  That is, this
describes a _homogeneous_ linked list, where all elements will have the
same type.

Lets say we want to write a function `sum` that takes a `llist` of
numbers and adds them up.  We now need to describe its type in terms of the
contents, which will be an `int`:

```
let rec sum (l : int llist) : int =
  match l with
    | Empty -> 0
    | Link(first, rest) -> first + (sum rest)
```

When we construct `llist`s, we do _not_ need to provide any extra type
information – OCaml figures it out for us.  For example, we can write:

```
let l1 = Link(1, Empty);;
let l2 = Link("a", Empty);;
```

Here, `l1` will have type `int llist`, and `l2` will have type
`string llist`.

### Linked Lists, Built-in

It turns out that our definition of `llist` above is important enough that
a version of it is built into OCaml, just with slightly different names and
syntax.  The built-in equivalent of `Empty` is written `[]`, and
`Link(first, rest)` is written `first::rest`.  The syntax `[a;b;c]`
is shorthand for `a::b::c::[]`.  The type of built-in lists is `'a
list`, which can be specialized for any list contents.  For example, we could
rewrite `sum` above as:

```
let rec sum2 (l : int list) : int =
  match l with
    | [] -> 0
    | first::rest -> first + (sum2 rest)
```

And we could test it by creating tests with `t_int`:

```
(* these would go in the suite list *)
t_int "sum2_empty" (sum2 []) 0;
t_int "sum2_single" (sum2 [5]) 5;
t_int "sum2_longer" (sum2 [3; 4; 5]);
t_int "sum2_longer2" (sum2 3::4::5::[]);
```

Note that the last two tests mean the same thing; they are just different ways
of writing the same list containing 3, 4, and 5.

Since lists are quite a fundamental structure, we will end up using them
frequently; handy functions to use with lists are (here)[http://caml.inria.fr/pub/docs/manual-ocaml/libref/List.html],
and we'll talk about them more as we build up more experience with OCaml.

### Exercises

1. Write and test a function `increment_all` that takes an `int
  list` and produces a new `int list` with all the elements increased by
  1.

2. Write and test a function `long_strings` that takes a `string
  list` and an `int` and produces a new `string list` that contains all
  the strings that had length greater than the given `int`.  You can get
  the length of a string with the function `String.length`.  Other string
  functions are documented (here)[http://caml.inria.fr/pub/docs/manual-ocaml/libref/String.html].

3.  Write and test a function `every_other` that takes a `'a list`
  (a list with elements of any one type), and produces a new list that
  contains every other element from the given list, starting with the first
  element.

4. Write and test a function `sum_all` that takes an `int list
  list` (that is, a list of lists of integers), and returns an `int list`
  that contains the sums of the sub-lists.


## Tuples

There are many times in programs where we wish to return more than one value.
For example, when returning a pair of key and value from a hash-table data
structure, when returning an average and its standard deviation, or when
representing a two (or three)-dimensional point, to name a few.

OCaml has a built-in way of handling these cases called `tuples` (many other
languages do as well).  To create a tuple, we enclose two or more values in
parentheses:

```
let tup = (1, "a", []);;
```

To access the values in a tuple, we can use a special kind of let binding,
where we give names to the positions of a tuple value:

```
let tup = (1, "a", []);;
let (one, a, empty_list) = tup;
(*
  one is 1
  a is "a"
  empty_list is []
*)
```

Since pairs—tuples of exactly two elements—are quite common, there are also
two built-in functions, `fst` and `snd`, that get the first and second
component of a two-element tuple, respectively.

The `type` of a tuple is written with `*` characters separating the
components' types, and surrounded by parentheses.

```
let increment_snd (t : (string * int)) : (string * int) =
  (fst t, 1 + (snd t));;

(increment_snd ("a", 5)) (* returns the pair ("a", 6) *)
```

### Exercises

1. Implement and test a function called `sum_of_squares`, which takes a `(int *
int) list` and produces a `int` that is the sum of the squares of the pairs in
the list.

2. Implement and test a function called `remainders`, which takes a `int list`
and a `int`, and produces a `(int * int) list`. The resulting list should
contain the dividend and the remainder of dividing by the given number. For
example, `(remainders [4, 6, 11] 3)` should produce `[(1, 1); (2, 0); (3, 2)]`

## `option`

A common way of handling failure that we've already seen is raising exceptions
with `failwith`.  This works well when an operation is truly nonsensical.
However, it forces programs to use a different class of features— exceptions
and exception handlers—to handle failing behaviors.  Sometimes, the failure of
an operation is a reasonable outcome, and having a way to report a failure, or
the absence of an answer, with a normal value rather than an exception is quite
useful.

Consider the problem of finding and returning the first element in a list that
matches a particular predicate:

```
let rec find (l : 'a list) (pred : 'a -> bool) : 'a =
  match l with
    | [] -> failwith "Not found"
    | x::xs -> if pred x then x else find xs pred;;

(find [1;2;3] (fun n -> n > 4);; (* raises an error *)
(find [1;2;3] (fun n -> n > 2);; (* returns 3 *)
```

When the element isn't found, we cannot return a value of type `'a`,
because the algorithm hasn't found one.  It seems we have to throw an error,
as there is nothing left for us to do.  This certainly limits the utility of
`find`, which now needs a companion `contains` if is to be useful on
lists that aren't already known to have a matching element.

It would be convenient if we had a value that represented that there is
**no** appropriate value to return in the empty case.  Similarly, it would
be useful to have the counterpart, a representation of being able to provide
**some** appropriate value.  OCaml provides just such a datatype, called
`option`, which is built-in.  If we wrote the definition ourselves, it
would look like:

```
type 'a option =
  | None
  | Some of 'a
```

That is, an `option` is either `None`, which we can use to indicate
failure or the lack of an appropriate value, or `Some`, which contains a
single field that is a value of the option's type.  To write `find` using
option, we would write:

```
let rec find_opt (l : 'a list) (pred : 'a -> bool) : 'a option =
  match l with
    | [] -> None
    | x::xs -> if pred x then Some(x) else find xs pred;;

(find_opt [1;2;3] (fun n -> n > 4);; (* returns None *)
(find_opt [1;2;3] (fun n -> n > 2);; (* returns Some(3) *)
```

Now a program that calls `find`, rather than using an exception handler to
manage the not found case, can simply `match` on the `option` that is
returned to decide what to do.

Note that `option`s aren't always better than exceptions, as sometimes it's
difficult for the caller to know what to do when `None` is returned.  But
in many cases, when “failure” is something that the caller can reasonably
react to, returning an `option` is a much more natural choice.

### Exercises

1. Write and test a function `mean` which takes an `int list` and produces an
`int option`, where it returns `None` if the list is empty, and a `Some`
containing the mean of the numbers if it isn't.

2. Write and test a function `list_max` which takes an `int list` and produces
an `int option`, where it returns `None` if the list is empty, and a `Some`
containing the largest element in the list if it isn't empty.

<a id="neonate"></a>
## A First Compiler

Next, we're going to implement a compiler.

It's not going to be terrifically useful, as it will only compile a very small
language – integers.  That is, it will take a user program (a number), and
create an executable binary that prints the number.  There are no files in
this repository because the point of the lab is for you to see how this is
built up from scratch.  That way, you'll understand the infrastructure that
future assignments' support code will use.

### The Big Picture

The heart of each compiler we write will be an OCaml program that takes an
input program and generates assembly code.  That leaves open a few questions:

- How will the input program be handed to, and represented in, OCaml?
- How will the generated assembly code be run?

Our answer to the first question is going to be simple for today: we'll expect
that all programs are files containing a single integer, so there's little
“front-end” for the compiler to consider.  Most of this lab is about the
second question – how we take our generated assembly and meaningfully run it
while avoiding both (a) the feeling that there's too much magic going on,
and (b) getting bogged down in system-level details that don't enlighten us
about compilers.

### The Wrapper

(The idea here is directly taken from [Abdulaziz
Ghuloum](http://scheme2006.cs.uchicago.edu/11-ghuloum.pdf)).

Our model for the code we generate is that it will start from a C-style
function call.  This allows us to do a few things:

- We can use a C program as the wrapper around our code, which makes it
  somewhat more cross-platform than it would be otherwise
- We can defer some details to our C wrapper that we want to skip or leave
  until later

So, our wrapper will be a C program with a traditional main that calls a
function that we will define with our generated code:

```
#include <stdio.h>

extern int our_code_starts_here() asm("our_code_starts_here");

int main(int argc, char** argv) {
  int result = our_code_starts_here();
  printf("%d\n", result);
  return 0;
}
```

So right now, our compiled program had better return an integer, and our
wrapper will handle printing it out for us.  The syntax
`asm("our_code_starts_here")` tells a compiler like `gcc` or `clang` to not do
any platform-specific name-alterations, and to use the provided name exactly
as it appears.  This makes it so the names that the compiler tries to find in
object files don't vary across platforms (not something I'd recommended in
general, but quite useful for our purposes).

We can put this in a file called `main.c`.  If we try to compile it, we get an
error:

```
⤇ clang -g -o main main.c
Undefined symbols for architecture x86_64:
  "our_code_starts_here", referenced from:
      _main in main-1a486d.o
ld: symbol(s) not found for architecture x86_64
clang: error: linker command failed with exit code 1 (use -v to see invocation)
```

That's because it's our job to define `our_code_starts_here`.  That's what
we'll do next.

### Hello, x86

Our next goal is to:

- Write an assembly program that defines `our_code_starts_here`
- Link that program with `main.c` and create an executable

In order to write assembly, we need to pick a syntax and an instruction set.
We're going to generate 32-bit x86 assembly, and use the so-called Intel
syntax (there's also an AT&T syntax, for those curious), because [I like a
particular guide](http://www.cs.virginia.edu/~evans/cs216/guides/x86.html)
that uses the Intel syntax, and because it works with the particular assembler
we'll use.

Here's a very simple assembly program, matching the above constraints, that
will act like a C function of no arguments and return a constant number (`37`)
as the return value:

```
section .text
global our_code_starts_here
our_code_starts_here:
  mov eax, 37
  ret
```

The pieces mean, line by line:

- `section .text` – Here comes some code, in text form!
- `global our_code_starts_here` – This assembly code defines a
  globally-accessible symbol called `our_code_starts_here`.  This is what
  makes it so that when we generate an object file later, the linker will know
  what names come from where.
- `our_code_starts_here:` – Here's where the code for this symbol starts.  If
  other code jumps to `our_code_starts_here`, this is where it begins.
- `mov eax, 37` – Take the constant number 37 and put it in the register
  called `eax`.  This register is the one that compiled C programs expect to
  find return values in, so we should put our “answer” there.
- `ret` – Do mechanics related to managing the stack which we will talk about
  in much more detail later, then jump to wherever the caller of
  `our_code_starts_here` left off.

We can put this in a file called `our_code.s` (`.s` is a typical extension for
assembly code), and then we just need to know how to assemble and link it with
the main we wrote.

### Hello, `nasm`

We will be using a program called [nasm](http://www.nasm.us/) as our
assembler, because it works well across a few platforms, and is simple to use.
The main way we will use it is to take assembly (`.s`) files and turn them
into object (`.o`) files that traditional compilers like `clang` or `gcc` can
work with.  The command we'll use to build with nasm is:

```
⤇ nasm -f elf32 -o our_code.o our_code.s
```

This creates a file called `our_code.o` in [Executable and Linkable
Format](https://en.wikipedia.org/wiki/Executable_and_Linkable_Format).  We
won't go into detail (yet, depending on what we have time for in the course)
about this binary structure.  For our purposes, it's simply a version of the
assembly we wrote that our particular operating system understands.

If you are on OSX, you can use `-f macho` rather than `-f elf32`, which will
produce an OSX-compatible object file.

With this in hand, and we ought to be able to compile it into a binary along
with a C source file just like any other object file generated from C.  For
example:

```
⤇ clang -g -o our_code main.c our_code.o
```

But this gives an error:

```
/usr/bin/ld: i386 architecture of input file `our_code.o' is incompatible with i386:x86-64 output
collect2: error: ld returned 1 exit status
```

This happens because the default (on the department machines) is to generate
binaries for 64-bit x86, and we're targeting 32-bit x86.  So we need to tell
`clang` that's what we want:

```
⤇ clang -g -m32 -o our_code main.c our_code.o
```

Now we can run our code:

```
⤇ ./our_code
37
```

Note that I will almost always include the `-g` option on uses of `clang`,
because it's always handy to have debugging information turned on.

### Hello, Compiler

With this pipeline in place, the only step left is to write an OCaml program
that can generate assembly programs.  Then we can automate the process and get
a pipeline from user program all the way to executable.

A very simple compiler might just take the name of a file, and output the
compiled assembly code on standard output.  Let's try that; here's a simple
`compiler.ml` that takes a file as a command line argument, expects it to
contain a single integer on one line, and generates the corresponding assembly
code:

```
open Printf

(* A very sophisticated compiler - insert the given integer into the mov
instruction at the correct place *)
let compile (program : int) : string =
  sprintf "
section .text
global our_code_starts_here
our_code_starts_here:
  mov eax, %d
  ret\n" program;;

(* Some OCaml boilerplate for reading files and command-line arguments *)
let () =
  let input_file = (open_in (Sys.argv.(1))) in
  let input_program = int_of_string (input_line input_file) in
  let program = (compile input_program) in
  printf "%s\n" program;;
```

Put this into `compiler.ml`, and create another file `87.int` that
contains just the number 87, then run:

```
⤇ ocaml compiler.ml 87.int

section .text
global our_code_starts_here
our_code_starts_here:
  mov eax, 87
  ret
```

How exciting!  We can redirect the output to a file, and get an entire
pipeline of compilation to work out:


```
⤇ ocaml compiler.ml 87.int > 87.s
⤇ nasm -f elf32 -o 87.o 87.s
⤇ clang -m32 -o 87.run main.c 87.o
⤇ ./87.run
87
```

If we like, we could capture this set of dependencies with a `make` rule:

```
%.run: %.o
	clang -m32 -o $@ main.c $<

%.o: %.s
	nasm -f elf32 -o $@ $<

%.s: %.int
	ocaml compiler.ml $< > $@
```

If we put that in a `Makefile`, then we can just run:

```
⤇ make 87.run
```

and we have the definition of our compiler.

### Is that it?

This defines a useful pipeline for getting from strings to assembly to a
binary.  It got us to the point where we have an OCaml program that's defining
our translation from input program to assembly code.  Our input programs are
pretty boring, so those will need to get more sophisticated, and
correspondingly the function `compile` will need to become more impressive.
That's where our focus will be in the coming weeks.

In the meantime, you have a little compiler to play with.  Can you think of
any other interesting input program formats to try, or tweaks to the generated
output to play with?

### Handin

In the `compiler` directory, make sure to add your `Makefile`, `compile.ml`,
and `main.c` for this part, and submit. Don't hand in any `.s`, `.o`, or `.run`
files. We're just going to check that we can make a source file and run it
through this process.


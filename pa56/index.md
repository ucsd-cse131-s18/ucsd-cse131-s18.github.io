# Diamondback

![A diamondback](https://upload.wikimedia.org/wikipedia/commons/d/d4/Crotalus_ruber_02.jpg)

[Link to your own repo](http://classroom.github.com/a/0Fz2Ae2J)

In PA5, you will be implementing a compiler for the Diamondback language, a
small language with functions, numbers, booleans, and _tuples_. This is
**closed collaboration**.

In PA6, you will be implementing tuple printing and deep equality checking in
C, and augmenting our running `main` function in C, to print tuple values,
check structural equality, and pass multiple command-line arguments.

## Language

Diamondback builds on Cobra and adds support for tuples. The main additions to
the language are the following:

* tuple expressions
* accessor for getting the contents of tuples
* checking if a value is a tuple
* getting the length of a tuple
* checking the structural equality of tuples

### Concrete Syntax
Diamondback adds the following to the concrete syntax of Cobra
```
<expr> :=
  ...
  | (tup <expr list>)
  | (tup-len <expr>)
  | (tup-get <expr> <expr>)
  | (is-tup <expr>)
  | (= <expr> <expr>)
```

### Syntax Additions

The main additions in Diamondback are _tuple expressions_. With it are
primitives for checking if a value is a tuple (`is-tup`), getting the number of
elements in a tuples (`tup-len`), and getting an element from a tuple
(`tup-get`), and doing a deep comparison of tuple (`=`). Tuple expressions are a series of any number of comma-separated
expressions enclosed in parentheses.

In addition to the tuple examples from PA4, here are some additional examples:

Example 1: 
```
(tup 2 3 4)
```
The above expression will create a three element tuple with values '1', '2',
and '3'. 

Example 2:
```
(let ((x (tup 1 2))) (is-tup x))
```
The above expression will check if `x` is a tuple (which it is and will return
`true`)

Example 3:
```
(tup-len (tup 1 2 3 4 5 6))
```
The above expression will return the length of the tuple, which is `6`

Example 4:
```
(tup-get (tup 11 22 33 44) 2)
```
The above expression will return the tuple element at index `2`, which is `33`

Example 5: 
```
(= (tup 7 8 (tup 1 2)) (tup 7 8 (tup 1 2)))
```

The above expression will return 'true' because the elements of each tuple (as well as the elements of nested tuples) all match. You will be implementing this deep equality checking in main.c as part of PA6. 


Finally, `is-tuple` is a primitive, like `isNum` and `isBool`, but checks for
tuple-ness.

In the abstract syntax these are represented as:

```
type expr =
  ...
  | ETuple of expr list

type prim1 =
  ...
  | IsTuple
  | TupLen

type prim2 =
  ...
  | TupGet
```

The first `expr` in `TupGet` is a tuple expression, and the second one is the
expression for the 0 based index.

### Deep equality (`=` operator)

Diamondback implements a new equality operator, using a single equals sign. This
new operator performs a deep equality check between two values by calling the C
function `deep_equals`. You must implement this function for PA6.

The behavior of the `=` operator is as follows:

1. If the inputs are both tuples, perform elementwise comparison between the two
   tuples. If the lengths are the same and all the elements are the same, return
   true (the properly tagged value). Otherwise, return false (tagged).
2. If the inputs are anything else, perform regular value comparison.

### Semantics and Representation of Tuples

#### Tuple Heap Layout

Tuples expressions should evaluate their sub-expressions in order, and store the
resulting values on the heap. The layout for a tuple on the heap is:

```
 (first 4 bytes)  (4 bytes)  (4 bytes)    ...   (4 bytes)
+---------------+-----------+-----------+-----+-----------+
| # of elements | element_0 | element_1 | ... | element_n |
+---------------+-----------+-----------+-----+-----------+
```

One word is used to store the _number_ of elements, n, in the tuple and the
subsequent words are used to store the values themselves.

A _tuple value_ is stored in variables and registers as **the address of the
first word** in the tuple's memory (the one containing the count of elements).
Now, our tagging convention is as follows:

- Numbers: `1` in the least significant bit
- Booleans: `10` in the least significant bits
- Tuples: `00` in least two significant bits

Visualized, the type layout is:

```
0xWWWWWWW[www1] - Number
0xFFFFFFF[1110] - True
0x7FFFFFF[1110] - False
0xWWWWWWW[ww00] - Tuple
```

Where `W` is a "wildcard" nibble and `w` is a "wildcard" bit.

#### Accessing Tuple Contents

In a _tuple access_ expression, like

```
(tup-get (tup 6 7 8 9) 1)
```

The behavior should be:

1.  Evaluate the tuple expression (the expression inside the parentheses),
    and then the expression that follows the tuple.
2.  Check that the tuple is actually a tuple by looking for the appropriate tag
    bits, and signal an error containing `"expected a tuple"` if not.
3.  Check that the index value is a number, and signal an error containing
    `"expected a number"` if not.
4.  Check that the index number is a valid index for the tuple value (i.e.
    between `0` and the stored number of elements in the tuple minus
    one.  Signal an error containing `"index too small"` or `"index too large"`
    as appropriate.
5.  Evaluate to the tuple element at the specified index.

You _can_ do this with just `EAX`, but it causes some minor pain. The register
`ECX` has been added to the registers in `instruction.ml` – feel free to
generate code that uses both `EAX` and `ECX` in this case. This can save a
number of instructions. Make sure that your implementation does not overwrite the
value stored in the `ECX` register before you use it!

You also may want to use an extended syntax for `mov` in order to combine these
values for lookup.  For example, this kind of arithmetic is allowed inside
`mov` instructions:

```
  mov eax, [eax + ecx * 4 + 0]
```

which corresponds to our new `RegOffsetReg` instruction type:

```
RegOffsetReg(EAX, ECX, 4, 0)
```

This would access the memory at the location of `eax`, offset by the value of
`ecx * 4`. So if the value in `ecx` were, say `2`, this may be part of a scheme
for accessing the first element of a tuple (there are other details you should
think through here; this is _not_ a complete solution).

Neither `ECX` nor anything beyond the typical `RegOffset` is _required_ to make
this work, but you may find it interesting to try different shapes of
generated instructions.

#### General Heap Layout

The register `EBX` has been designated as the heap pointer. The provided
`main.c` does a “large” `calloc` call, and passes in the resulting address as an
argument to `our_code_starts_here`. The support code provided fetches this value
(as a traditional argument), and stores it in `EBX`.

It is **up to your code** to ensure that the value of `EBX` is always the
address of the next block of free space (in _increasing_ address order) in the
provided block of memory.

#### Representation of empty tuples

In our language, an empty tuple can be created with `(tup)`. The ability to
create an empty tuple raises a question: how should this value be represented
in memory?

We have two main choices. We could stay consistent with the tuple representation
we laid out above and allocate a zero-length tuple on the heap. In other words,
the tuple value will be a regular old tuple value and point to the allocated
tuple in the heap. In the heap, the first word of the tuple (its length) would
be zero, and there would be no other words allocated for the tuple.

The other option is to be a bit more memory-conscious (at the consequence of
losing some consistency) and not use space on the heap at all. In this case, we
need to come up with a special tuple value that represents an empty tuple. This
special value must be unique (it must be different than all valid tuple
representations).

For our implementation, we have chosen the second option. Our special value will
be 0. Since 0 is never a valid pointer, this is sufficient (any valid tuple
value will be an actual pointer into the heap). This value also has the right
tag bits (zeros in the two least significant bits). In the provided main.c file,
this special value is accessible via the macro `TUPLE_NULL`.

When you implement the tuple operations in C for PA6, keep in mind that your
inputs could be empty tuples!

#### Interaction with Existing Features

Any time we add a new feature to a language, we need to consider its
interactions with all the existing features.  In the case of Diamondback, that
means considering:

- Function calls and definitions
- Tuples in binary and unary operators
- Let bindings

We'll take them one at a time.

- **Function calls and definitions**: Tuple values behave just like other values
  when passed to and returned from functions – the tuple value is just a
  (tagged) address that takes up a single word.
- **Tuples in let bindings**: As with function calls and returns, tuple values
  take up a single word and act just like other values in let bindings.
- **Tuples in binary operators**: The arithmetic expressions should continue to
  only allow numbers and signal errors on tuple values. There is one binary
  operator that doesn't check its types, however: `==`. We need to decide what
  the behavior of `==` is on two tuple values. Note that we have a (rather
  important) choice here. Clearly, this program should evaluate to `true`:

  ```
  (let ((t (tup 4 5))) (== t t))
  ```

  However, we need to decide if

  ```
  (== (tup 4 5) (tup 4 5))
  ```

  should evaluate to `true` or `false`. That is, do we check if the _tuple
  addresses_ are the same to determine equality, or if the _tuple contents_ are
  the same. For this assignment, we'll take the somewhat simpler route and
  compare _addresses_ of tuples, so the second test should evaluate to `false`.
  (Note: you're expected to implement deep comparison of values using `=` for
  PA6, not PA5).
- **Tuples in unary operators**: The behavior of the unary operators is
  straightforward, with the exception that we need to implement `print` for
  tuples in PA6. We could just print the address, but that would be somewhat
  unsatisfying. Instead, we should recursively print the tuple contents, so that
  the program

  ```
  (print (tup 4 (tup true 3)))
  ```

  actually prints the string `"(4,(true,3))"`. This will require some careful
  work with pointers in `main.c`. You'll be implementing printing for tuples
  in `main.c` for PA6.

#### Some notes on pointer arithmetic

Note that in C, pointer arithmetic is automatically scaled according to the type
of the pointer. For instance, since the `int` type corresponds to 4 bytes in
memory, a pointer of type `int *` can only point to 4-byte aligned addresses.
As such, performing arithmetic on an `int *` will automatically give a 4-bye
aligned address.

In other words, if you add `1` to an `int *`, the value of the pointer will
actually increase by 4. Similarly, if you add `1` to a `char *` (the type `char`
corresponds to 1 byte in memory), the value of the pointer will increase by 1.

Here is some code that demonstrates this for `int`s:

```
int int_ptr[] = {1, 2, 3}; // arrays can be treated as pointers to their first element

int first = *int_ptr; // gets the first element of the array
int second = *(int_ptr + 1); // gets the second element of the array
int third = *(int_ptr + 2); // gets the third element of the array
```

## User Inputs

In this assigment, we'll be extending what can be passed as input to our programs.
There are three ways `input` will be handled:
1. `./output/foo.run` will run with `input` set to `false`
2. `./output/foo.run <arg1>` will run with `input` set to `<arg1>`
3. `./output/foo.run <arg1> <arg2> ...` will run with `input` set as the tuple
`(<arg1>,<arg2>,...)`

For example, supposed you define the program `foo.diamondback`
```
((define our_main (input) input))
```
and execute it by running the following line
```
./output/foo.run 1 2 3 4
```
The output of the program should be
```
(1,2,3,4)
```
Otherwise, if you execute the line
```
./output/foo.run 55
```
the output of the program should be
```
55
```

You should be implementing this feature by extending how you handle command-line
arguments.

### Tuple input and the heap

Note that if the command line input is not a single value, the tuple must be
allocated on the heap before `our_code_starts_here` is called. This way, the
second argument to `our_code_starts_here` is always a tagged value (either a
number, boolean, or tuple value).

Because of this, `ebx` may not point to the begining of the block of memory
allocated in main.

## Testing

**PA5**
Testing is similar to past assignments. Be sure to run valgrind through your
programs to check that you're handing memory correctly. Similar to PA3, you
can either run Valgrind on each individual program with
```
valgrind output/XXX.run <arg1> <arg2> ...
```
or make a test in `myTests.ml` with valgrind by writing
```
tvg_i_main <name> <program> <expected> <args>
```

**PA6**
Since the primary focus of PA6 is getting familiar with pointer arithmetic,
the main things to test are your tuple printing and deep comparison functions.
Therefore, we've provided you with a compiler that correctly implements tuples.
For your convenience we've put the test functions used for testing your BST and
list data structures so that you can import your tests from the previous
assignment. You'll need to override `ds.ml` with your data structure
implementation.

## Deliverables

**PA5** 
- Implement cases for `ETuple`, `IsTuple`, `TupLen`, `TupGet` in
  `well_formed_e`: These should return the _static_errors_ that can arise from
  tuple and tuple access operations respectively.
- Implement cases for `ETuple`, `IsTuple`, `TupLen`, `TupGet` in `compile_expr`.

Note: Equality between tuples for PA5 should just be a shallow check 

**PA6**
- Implement tuple printing and `deep_equals` in `main.c`
- multiple command line input values should be interpreted as a tuple in
  `main.c`

## FAQ

**Q. Should we keep tuple length unshifted when we store it as the first
element of the tuple or should we shift it?**

A. Depends on your implementation. If unshifted, remember to treat it
differently than your regular constants. If shifted, remember to unshift it when
checking for index out of bounds and in `print`. But storing it shifted could be
useful.

**Q. Do all elements of a tuple have to be the same type?**

A. No

**Q. Why are we using size of `DWord` if element sizes are of size `Word`?**

A. [Assembly is weird](http://www.cs.virginia.edu/~evans/cs216/guides/x86.html)

**Q. Does our max int change from the previous assignment?**

A. Does the number of bits to represent our data change?

**Q. What should happen if we compare two different type of values?**

A. `==` should return false. Here are more examples:

In PA5 (without deep tuple equality):
```
(== (tup 1 2) 1)                   --> false
(== (tup 1 2) true)                --> false
(== (tup 1 2) (tup 1 2))           --> false

(let ((t (tup 1 2))) (== t t))     --> true
```

In PA6, with deep equality with `=`:
```
(= (tup 1 2) (tup 1 2))       --> true
(let ((t (tup 1 2))) (= t t)) --> true
```

## Recommended Ways To Start

PA5 
1. Get tuple creation and access working for tuples containing two elements, and
   **test** as you go. This is very similar to the pairs code from lecture.
   So, you can just put a `Const(2)` as the first word, use the 2nd and the 3rd
   words for the elements.
2. Modify the primitives to handle tuples appropriately (it may
   be useful to skip `print` at first). **Test** as you go.
3. Make tuple creation and access work for tuples of _any_ size. **Test** as you
   go.

PA6 
1. Implement tuple printing for flat tuples, add tests as you go. 
2. Work on printing for nested tuples as well. 
3. Add structural equality checks for tuples in `deep_equals`. Ensure that it
   works for nested tuples. 

A note on support code – a lot is provided, but, as always, you can feel free
to overwrite it with your own implementation if you prefer.

## Turning in

There will be **two** separate assignments on Gradescope -- one for PA5, and one
for PA6. Both of the assignments will be submitted as usual.

For PA5 (closed collaboration), we will test your implementation of tuples.

For PA6, we will test **only** your implementation of `deep_equals` and
tuple printing. This means that we will use a correct compiler implementation,
and we will link the produced assembly with your implementation in `main.c`.
Tests will simply call `print` in Diamondback and test for structural equality
with the `=` operator. We will also test your handling of multiple command line
arguments.

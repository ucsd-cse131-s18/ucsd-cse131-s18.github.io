---
layout: page
title: "PA7 – Garter"
doodle: "https://camo.githubusercontent.com/e4551b88fb523b4897537330aa769e69d1410834/68747470733a2f2f75706c6f61642e77696b696d656469612e6f72672f77696b6970656469612f636f6d6d6f6e732f7468756d622f372f37362f436f6173745f4761727465725f536e616b652e6a70672f3139323070782d436f6173745f4761727465725f536e616b652e6a7067"
---

# PA7 –– Garter (Closed Collaboration)

The Garter language manages its memory automatically.  You will implement the
automated memory management.

Classroom link: https://classroom.github.com/a/w8o9VjGI

It is due by 11:59pm on Thursday, May 31.

## Language

Garter (the language) is much the same as Diamondback, with some additions:

```
expr :=
    | (while <expr> <expr>) ; while loops
    | (begin <expr> ...)    ; sequencing
    | (<id> := <expr>)      ; variable assignment
```

1. `while` loops, which evaluate their condition (the first expression), then
evaluate the body if the condition didn't evaluate to `false`, then repeat
until the condition evaluates to a non-`false` value. The entire while loop
evaluates to false.
2. `begin` for sequencing, which evaluate the given expressions in order,
giving the result of the final expression as the result of the entire
expression.
3. `<id> := <expr>` for variable assignment, which changes the value stored on
the stack for a given variable. The expression evaluates to the newly
assigned value.

Their implementation is provided for you. The reason they are included is
that, for testing the garbage collector, it's useful to be able to easily
loop over the allocation of data!

Here's an example program that uses all three features to calculate the sum
of `input`:

```
(
(define our_main (input)
    (let ((sum 0))
       (begin
        (while (> input 0)
          (begin
            (sum := (+ sum input))
            (input := (- input 1))))
        sum)))
)
```

## Runtime and Memory Model

### Value Layout

The value layout is extended to keep track of information needed in garbage collection:

- `0xXXXXXXX[xxx1]` - Number
- `0xFFFFFFF[1110]` - True
- `0x7FFFFFF[1110]` - False
- `0xXXXXXXX[xx00]` - Tuple

  `[ GC word ][ element count ][ value 1 ][ value 2 ][ ... ]`

On the heap, each tuple has **one additional word** (we will call it the _GC
word_). It is detailed below, and is used for bookkeeping during garbage
collection.



### Checking for Memory Usage, and the GC Interface

Before allocating a tuple, the Garter compiler checks that enough space is
available on the heap. If enough words _aren't_ available, then the generated
code:

1. Calls `try_gc` with several values:
    - `alloc_ptr`: the current value of EBX (where the next value would be
      allocated without GC)
    - `bytes_needed`: the number of _bytes_ that the runtime is trying to
      allocate
    - `first_frame`: the current value of EBP
    - `stack_top`: the current value of ESP

2. Then expects that `try_gc` either:
   - Makes enough space for the value (via the algorithm described below), and
     returns a new address to use for `EBX`, which should point to the first
     available space in the heap, OR
   - Terminates the program in with an error message `out of memory` if enough
     space cannot be made for the value.

There are a few other pieces of information that the algorithm needs, which the
generated code and `main.c` collaborate on setting up.

To run the mark/compact algorithm, we require:

  - The heap's starting location: This is stored in the global variable `HEAP`
    on startup in `main.c`.

  - The heap's ending location and size: These are stored in `HEAP_END` and
    `HEAP_SIZE` as global variables in `main.c`.

  - Information about the shape of the stack: We know that in our model of the
    stack frame
    - `[EBP]` holds the return address, and `[EBP+4]` holds the stored
      previous value of `[EBP]`
    - The words between `[ESP]` and `[EBP]` hold the local variables and
    arguments of the current call

  - The beginning of the stack: This is stored in the `STACK_BOTTOM`
  variable. This is set by the instructions in the prelude of
  `our_code_starts_here`, using two words past the initial value of `ESP`.
  This is a useful value because the region between `[ESP]` and the stack
  bottom is the place where all of the root set values are stored.

  - The top of the stack: This is known by our compiler, and always has the
    value of `ESP` at the point of garbage collection.

### Calling Convention

We use a calling convention similar to the one discussed in class, so at any
given moment there are a number of function calls on the stack, each with
arguments and local variables:

```
esp ->  [local var N        ]   <- stack_top
        [...                ]
        [local var 2        ]
        [local var 1        ]
        [arg 1              ]
        [arg 2              ]
        [...                ]
        [arg N              ]
ebp ->  [return address     ]   <- first_frame
        [prev ebp value     ]
        ---------------------
        [local var N        ]
        [...                ]
        [local var 2        ]
        [local var 1        ]
        [arg 1              ]
        [arg 2              ]
        [...                ]
        [arg N              ]
        [return address     ]
        [prev ebp value     ]
        ---------------------
        [local var N        ]
        [...                ]
        [local var 2        ]
        [local var 1        ]
        [arg 1              ]
        [arg 2              ]
        [...                ]
        [arg N              ]
        [return address     ]
        [prev ebp value     ]
        ---------------------
        [ret ptr to main    ]
        [value of input     ]
        [value of heap start] <- STACK_BOTTOM
```

Two key things to note:

- On the right, we show the addresses stored in the arguments given to
`try_gc` which are passed on to the `gc` function you will write.
- At the bottom, we have the arguments to `our_code_starts_here`, and a
particular address stored in `STACK_BOTTOM`
- We made sure the compiler implements the invariant that `esp` will always
refer to the topmost valid value, and that there won't be any invalid values
in the local variables or the arguments on the stack. These form the root set
of the collection.

## Managing Memory

Your work in this assignment is all in managing memory. All of your work will
be done inside `gc.c` and you will write tests in `myTests.ml`.
Fundamentally, you will implement a mark/compact algorithm that reclaims
space by rearranging memory.

### Mark/Compact

The algorithm works in three phases:

1. **Mark**: Starting from all the references on the stack, all of the reachable
data on the heap is _marked_ as live. Marking is done by setting the
least-significant bit of the GC word to 1.

2. **Forward**: For each live value on the heap, a new address is calculated and
stored. These addresses are calculated to compact the data into the front of the
heap with no gaps. The forwarding addresses, which are stored in the remainder
of the GC word, are then used to update all the values on the stack and the heap
to point to the new locations. Note that this step does not yet _move_ any data,
just sets up forwarding pointers.

    In addition, addresses on the _stack_ should be updated to reflect these forwarding addresses in this step.

3. **Compact**: Each live value on the heap is copied to its forwarding
location, and has its GC word zeroed out for future garbage collections.

The end result is a heap that stores only the data reachable from the current
stack, in as little space as possible, starting from the front of the heap.
Allocation can proceed from the end of the compacted space by resetting `EBX`
to the first free slot in the heap.

### Testing

To test the garbage collector, you'll write programs in the language that
allocate different amounts of memory.

Testing works mostly as before, except that there are a few additional forms for
checking things relative to the garbage collector. The main program is
parameterized over an integer argument that allows you to select the size of the
heap in terms of (4-byte) words. This is exposed through the testing library as
well, so you can write:

```
tgc_main "gctest" 10 "(tup 1 2)" "(1, 2)"
```

and this will run the test with a heap size of 40 bytes.

You can also test for specific errors, for example in the case that there
will never be enough memory to fit the required data (how many words does
this example require?):

```
tgcerr_main "gctest" 8 "(tup 1 (tup 3 (tup 4 5)))" "out of memory"
```

The size of the heap is 100000 words by default.

You can add these in `test.ml` and run with `make test` and `./test`.

Note that you'll need to run from `ieng6`, because we are providing the
compiler as a black-box binary that generates assembly code (much like PA4
and PA6).

**Printing** – There's a helper, `print_mem`, defined for you in `gc.c`
that takes an array and a number of elements to print, and prints them one per
line like so:

```
  0/0x100df0: 0x1 (1)
  1/0x100df4: 0x0 (0)
  ...
  23/0x100e4c: 0x4 (4)
  24/0x100e50: 0xcab005e (212533342)
```

The first number is the 0-based index from the start of the array, and the
second is the memory address. After the colon is the value, in hex form and in
decimal form (in parentheses). This is a useful layout of information to have at
a glance for interpreting the structure of the heap.

There is a macro called `DEBUG_PRINT` defined at the top, and `print_mem`
uses this. You can set the `#define` for `DEBUG` to 1 or 0 to turn on or off
printing.

While automated testing and a debugger are both invaluable, sometimes there's
just no substitute for pretty-printing the heap after each phase in a
complicated test!

## Getting Started

Familiarize yourself with `gc.c` and the call to it from `main.c`. Then write
a small test; in `input/small.garter`, write:

```
((define our_main (_) (tup 1 2 3)))
```

Then build it:

```
$ make output/small.run
```

Now you can run it with different heap sizes. This program needs 5 words of
heap space based on the above memory layout (one gc word, one for tuple size,
and the other 3 for contents). We can see this by running it and using the
_first argument_ to specify heap size:

```
$ ./output/small.run 1
Allocation of 5 words too large for 1-word heap
$ ./output/small.run 3
Allocation of 5 words too large for 3-word heap
$ ./output/small.run 5
(1,2,3)
```

This error is coming from `try_gc` (go find it!).

Of course, we can also run out of memory from multiple allocations. Make a
file called alloc-multi.garter:

```
((define our_main (_)
    (let ((t1 (tup 1 2 3))
          (t2 (tup 3 4 5)))
        (tup t1 t2))))
```

Build it, and we can see how much space is needed, and how the error changes

```
$ ./output/alloc-multi.run 4
Allocation of 5 words too large for 4-word heap
$ ./output/alloc-multi.run 8
Out of memory: needed 5 words, but only 3 remain after collection
$ ./output/alloc-multi.run 12
Out of memory: needed 4 words, but only 2 remain after collection
$ ./output/alloc-multi.run 14
((1,2,3),(3,4,5))
```

Convince yourself _why_ this is happening by reading starter code.

The above programs actually use all the memory they allocate! But other
programs don't. For example, this program allocates a completely useless
tuple:

```
(
    (define our_main (_)
      (let ((t (tup 1 2)))
      (begin
        (t := (tup 3 4))
        (t := (tup 5 6))
        (t := (tup 7 8))
        t
      )
    )
)
```

This program allocates a bunch of useless tuples that are never used. We
should never need more than 8 words at a time (4 for the current value, 4 to
allocate the new one to overwrite `t` with) to store these useless tuples;
garbage can be collected to make more room. Yet, we'd still need to run (with
the starter code) with a heap size of 16 to make this run. You can view this
as your first task – get this program to run with a heap size of 8!

To do this you'll need to implement `mark`, `forward`, and `compact` in
`gc.c` according to the mark/compact algorithm we discussed in class.

You can do this incrementally:

- First, implement `mark`, `forward`, and `compact` just for single stack
frames in `our_main` that you understand well. Use only tuples containing
primitives like numbers and booleans. Use the printing functions in `gc`,
along with a debugger to help you see the shape of data you're working with.
Draw pictures and get a simple example working.
- Add tests with function calls to make the garbage collector run out of
memory somewhere other than `our_main`, and make sure it traverses the stack
correctly.
- Add tests with nested tuples and garbage, which will require doing a
worklist or recursive traversal in `mark` to find all the live data. Consider
tests that:
    - Have only a little bit of live data and lots of dead data
    - Have only a little bit of dead data and lots of live data
    - Have live data spread out over different parts of the heap
- Try adding some big tests using lists and bsts. You could allocate a big
BST structure, then get its height, and check that the whole BST is
collected, for example. You could do this in a loop to make sure only the
most recent BST is used at any point in time.

Draw pictures, check if the pictures you're drawing line up with what you're
seeing when you print the heap and when you use a debugger, and do your best
to work incrementally.

A heads up that there aren't a ton of lines of code needed to complete this.
We wrote around 250 lines in `gc.c`. You will have to think a lot about the
lines you write, but if you find yourself reaching into many hundreds of
lines, you may want to go back to design rather than trying to push forward
with a start that won't work.


## FAQ from previous years

**Q. What is the evaluation order of tuples?**

A. We evaluate the elements of the tuple before trying to allocate space for the
resulting pair, and evaluate the elements left-to-right.

**Q. Can I use a file to store the program of a test case ?**

A. Yes, write your program in `input/<filename>.garter` and in `myTests.ml`
you can use it as `(f_to_s "<filename>")` as an argument for `t`, `tgc`, etc,
which will pull in the contents as a string.


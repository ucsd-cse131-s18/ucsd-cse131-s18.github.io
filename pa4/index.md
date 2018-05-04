# Diamondback Testing -  Due Wednesday 5/09/2018 (Open Collaboration)

![A diamondback](https://upload.wikimedia.org/wikipedia/commons/d/d4/Crotalus_ruber_02.jpg)

[Link to your own repo](https://classroom.github.com/a/2vrakff6)

This assignment focuses on providing an introduction to tuples that will be implemented in the next PA.
You will implement two data structures — Binary Search Tree (BST) and List - through the use of tuples. You will be provided with one correct
and several buggy compilers. By first writing a few data structures before actually implementing the language, this helps with testing your future tuple implemetation. Notice how this is now close to becoming a useful language. 

## Language
Diamondback builds on Cobra and adds support for tuples. The main addition to the language are the following:
* tuple expressions
* accessor for getting the contents of tuples
* checking if a value is a tuple
* getting the length of a tuple

### Concrete Syntax
Diamondback adds the following to the concrete syntax of Cobra
```
<expr> :=
  ...
  | (tup <expr list>)
  | (tup-len <expr>)
  | (tup-get <expr>)
  | (is-tup <expr>)
```

#### Comments in Diamondback files

Comments can actually be written into s-expressions using the following three syntaxes:

;
Comments out everything to the end of line

#|, |#
Delimiters for commenting out a block

#;
Comments out the first complete s-expression that follows

This is built into the Core sexp parser, so the comments will be dropped before reaching your parser -- they are only for programmers to read. As an example from Real World Ocaml:

```
;; comment_heavy_example.scm
((this is included)
 ; (this is commented out
 (this stays)
 #; (all of this is commented
     out (even though it crosses lines.))
  (and #| block delimiters #| which can be nested |#
     will comment out
    an arbitrary multi-line block))) |#
   now we're done
   ))
```
parses into the following S-expression:

```
List(
  [List([Atom("this"); Atom("is"); Atom("included")]);
   List([Atom("this"); Atom("stays")]);
   List([Atom("and"); Atom("now"); Atom("we're"); Atom("done")]);
])
```

## Tuples and Supported Operations
Some examples of valid tuple expressions in our language:

### Example 1: 
```
(tup 1 2 3)
```
which creates a tuple that contains three elements, the values `1`, `2`, and `3`. When printed (either with `print` or as the answer to the program), this will display as `(1, 2, 3)`. When we want to talk about a tuple _value_ (as opposed to a tuple _expression_), we'll use the comma-separated notation `(1, 2, 3)`.


### Example 2: 
Tuple expressions can have sub-expressions that aren't values; these evaluate to values that become the elements of the created tuple.
```
(let ((x 2)) (tup x (+ x 2) (* x 3)))
```
which creates a tuple containing `2`, `4`, and `6`, which prints as `(2,4,6)`

### Example 3:
Tuples (or, as we'll see when we implement this, references to tuples) are values, and can be the elements of other tuples.
```
(tup 2 (tup false true) 10)
```
which creates a tuple with three elements, `2`, `(false, false)`, and `10`.

### Example 4: 
We can also get access to relevant information about tuples and their elements. For example,
```
(tup-len (tup 1 2 3))
```
returns the length of the tuple, in this case `3`

### Example 5: 
```
(is-tup (tup 1 false))
```
determines if the passed expression is a tuple, which is `true` in this case.

### Example 6: 
```
(tup-get (tup 4 5 6 7) 2)
```
returns the requested tuple element, in this case `6` (tuples are 0-indexed)

## Building Data Structures with Tuples

From the programmer's perspective, tuples are a simple feature, yet they give us plenty of power to write nontrivial programs.
In this assignment, you'll use tuples to implement two data structures – arbitrary length
lists and binary search trees. (You will be purely programming in
Diamondback, not in Ocaml, for this PA!) When building a new language, it's important to write some
simple, but nontrivial, programs to test that everything is working as intended. This
may also give you some ideas for how the language could be more pleasant to use or
otherwise improved, beyond small unit test cases.

### Lists
We can implement lists by chaining pairs (tuples of size 2),
where the first element is the value stored in the list, and the second element is another
list to the next element. For example, we can express the list `[1,2,3]` with the tuple
```
(tup 1 (tup 2 (tup 3 false)))
```
This will be printed as
```
(1,(2,(3,false)))
```
Note that we used `false` to indicate the end of the list above. You may assume that all
elements in a list will be numbers. You must also implement the following list functions

* link - new list with a single pair

`(link 0 false)` prints to `(0,false)`

* length - return the length of the list

`(length (link 0 (link 1 false)))` returns the value `2`

* sum - sum all elements in the list

`(sum (link 3 (link 7 false)))` returns the value `10`

* append - given a list and an element, append the element to the front of the list

`(append (link 2 (link 1 false)) 3)` returns the list `(3,(2,(1,false)))`

* reverse - return the list in reverse order

`(reverse (link 3 (link 2 (link 1 false))))` returns the list `(1,(2,(3,false)))`


### BSTs
Another interesting data structure to implement are binary search trees. Similar to lists,
we can use tuples to create nodes that form a BST. One way to represent a leaf with a key of `1`
and value of `101` would be creating the tuple
```
(tup (tup 1 101) (tup) (tup))
```
which will print out as
```
((1,101) () ())
```
Note that creating an empty tuple with `(tup)` is allowed, and produces a tuple with no elements (it would print as `()`).
Following this implementation, we can represent a BST with inserted key-value pairs
`2, 102` and `3, 103` (in that order) as:
```
(tup (tup 2 102) (tup) (tup (tup 3 103) (tup) (tup)))
```
which will be displayed as (it's tuple value is):
```
((2,102),(),((3,103),(),()))
```

Notice in the BST, the first element contains the key-value pair. In that pair, the the key is 0th element of the tuple, and the value is the 1st element of the tuple. The left child is the 1st element of the node, and the right child is the 2nd. Written out generically, we could say that a BST is:

- The empty tuple `()`, representing a leaf node
- A tuple value `((key,value), bst, bst)`, representing a node where
  - The 0th element contains the key-value pair. In that pair, the the key is 0th element of the tuple, and the value is the 1st element of the tuple.
  - The left child is the 1st element of the node, and the right child is the 2nd.

Similar to lists, you can assume that all keys will be numbers (values can be any value). You must implement the
following BST functions

* node - create a node with the given key and value, and no children 

`(node 1 4)` will create a child-less node with a key of `1` and value of `4`

* insert - insert a value given a key into the BST (keys must be unique, otherwise return the BST without modifying it)

`(insert (node 1 3) 2 4)` will return `((1,3), (), ((2,4), (), ()))`

* lookup - given a key, lookup its associated value

`(lookup (node 3 9) 3)` will return the value associated to the key `3`, `9` in this case. If the key
does not exist, return `false`

* height - calculate the height of the tree

`(height (insert (insert (node 1 2) 5 9) 22 0))` returns 3

* size - calculate the total count of nodes/leaves in the tree

`(size (insert (node 1 2) 3 4))` will return `2`

* inorder\_keys - return a list containing all stored keys in the tree in order

`(inorder_keys (insert (node 2 3) 1 5))` will return the list `(2, (3, false))` (e.g. using the representation of lists given before)

* inorder\_values - return a list containing all stored values in the tree in order

`(inorder_values (insert (node 2 3) 1 5))` will return the list `(3, (5, false))` (e.g. using the representation of lists given before)

### Implementing and Testing Lists and BSTs
Fill in your BST and List implementation in `ds.ml`. We have already given you a skeleton of the
required functions (detailed above) which we will be graded for correct implementation. You can define your own
helper functions but should NOT delete any of the required functions. You must correctly implement BST and List
implementations in `bst_impl` and `list_impl`. 

To help you test your implementations, you can write unit tests in `myDSTestList` in `myTests.ml`. 
We won't grade these tests directly, though you're welcome to include and use them in the graded tests, described below.

`t_i_main_list <test name> <test expression> <expected result> <command-line input argument>`

`t_i_main_bst <test name> <test expression> <expected result> <command-line input argument>`

To run your unit tests, do `make clean && make && ./test`

## Detecting Buggy Compilers

Tests help us find mistakes in our implementations. One way to assess the quality of tests (and a fun way to learn to write more thorough tests) is to check if they detect _known bad_ implementations. To that end, you'll pick or write a subset of tests that are designed to detect a few buggy implementations of Diamondback that we've written. The grader will run them against the correct implementation and against a buggy one, and tell you if the test noticed the difference.

To detect a buggy compiler means to write a test that produces different output on the correct compiler than 
the correct compiler. Your task is to write tests that cause the buggy compilers to fail, which we provided as binaries. 
Under the `/compilers` subdirectory, you are given a correctly implemented compiler binary, and 2 incorrect compiler binaries. Your task is to write test cases that catch these bugs.

All of these tests should be filled in `myBuggyCompilerTestList` in `myTests.ml`. 
Use `detect_buggy_compiler` to write a detection test. To check your detection attempt, do
`make clean && make && ./test`. 

Usage:
`detect_buggy_compiler <test name> <test code> <buggy compiler id> <command line arguments>` 

For example: 
`detect_buggy_compiler "buggy1" "((define our_main(input) (tup-len (tup 1 2))))" 1 [];`

If your test fails detecting a buggy compiler, you will see a message like this:
```==============================================================================
Error: suite:2:buggy1.

File "oUnit-suite-x#03.log", line 2, characters 1-1:
Error: suite:2:buggy1 (in the log).

Raised at file "src/oUnitAssert.ml", line 45, characters 8-27
Called from file "src/oUnitRunner.ml", line 46, characters 13-26

Detecting buggy1 failed

Correct compiler got: 2

buggy1 got: 2

------------------------------------------------------------------------------
==============================================================================
```

If your test successfully detects a buggy compiler, you will see a message like this:
```
==============================================================================
Test: buggy2 

buggy2 Detected
 
Correct compiler got: 2

buggy2 got: 938948948


==============================================================================
```

Check how many buggy compilers you've detected: 
`./grade-buggy.sh`

To run a single buggy compiler in command-line:
1. create a test file in input/ 

`echo "((define our_main(input) (tup-len (tup 1 2))))" > input/test.diamondback `

2. compile:

You can choose which compiler using COMPILER argument. COMPILER can be `[correct | buggy1 | buggy2 | ... ]`. 

`make output/test.run COMPILER=buggy1` 

3. run: 

`./output/test.run`

## Functions and Files for grading
1. `ds.ml` : `bst_impl`, `list_impl`
2. `myTests.ml` : `myBuggyCompilerTestList`

We will only be grading these three elements of your implementation. If you wish, you can create helper functions 
in these two files. 


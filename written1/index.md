---
layout: page
title: "Written Assignment 1"
doodle: "../doodle.png"
---

# Written Assignment 1

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
length limits, and though more per-question grade criteria are provided
below), so “wrong” answers can get significant credit if they are clear
enough that the mistake is understandable. The point is to have made
identifiable decisions with plausible justification and a concrete
specification.

## Giving Meaning to Errors

_(16 points, write no more than 1 page)_

In Boa, the course staff decided on a number of cases could cause errors –
the conditional part of ifs, mixing booleans and numbers in operators,
parsing user input, checking for overflow, and so on. Choose one such error
from Boa, and design behavior that it should have _other_ than producing an
error. For each:

- Describe the non-erroneous behavior
- Summarize how you would change the implementation to accommodate the new
  behavior
- Argue for why it's a good or a bad idea to have this behavior
- Give an example of a programming language that has similar behavior (hint,
  try running various operators on numbers and booleans in Python,
  JavaScript, Java, C, etc.)

Example (you cannot use this idea in your answer):

        I propose that the conditional part of if should not raise an error
        on non-boolean values. Instead, it should treat all non-`false`
        values (including 0) as `true`.

        To change this, I'd make if simply compare the value of the
        conditional with the representation of `false` directly, and jump to
        the false case if equal, and proceed to the then case otherwise. This
        would skip the extra instructions for checking with `true` explicitly
        and then having a third case that jumps to an error. Examples:

            (if 4 true false) would now evaluate to true rather than an error
            (if false true false) would evaluate to false

        The overall skeleton of generated if code would look like this,
        omitting the extra checking for boolean-ness.

            ... get condition to EAX ...
            cmp EAX, <false's representation>
            je else_label
            ... instructions for then case ...
            jmp done
            else_label:
            ... instructions for else case ...
            done:

        No representations need to change to accommodate this, just the
        instructions generated for the EIf case.

        This is a good idea because it makes it makes `if` generate fewer
        total instructions, resulting in smaller binaries and faster code.
        This is how the Racket programming language works, so there's
        precedent, as well; here are some examples in Racket:

            (if #t "a" "b") ; evaluates to "a"
            (if "hello" "a" "b") ; evaluates to "a"
            (if #f "a" "b") ; evaluates to "b"
            (if 0 "a" "b") ; evaluates to "a"

## Adding a New Value – `null`

_(16 points, write no more than 1 page)_

Imagine that you work on the team that develops Cobra for enterprise
customers. The project manager for Cobra comes back from a conference and,
full of enthusiasm, announces that the next release of Cobra must support a
`null` value, because it is a ubiquitous feature in other languages. When you
press for more details about the details of how `null` should work, the
project manager urges you to “make it work like in Java.”

Come up with a design and implementation plan for adding `null` to Cobra. You
should not turn in code. Rather, you should identify all the places that need
changes or additions, and what _decisions_ need to be made in order to pick
an implementation. Consider:

- Changes to concrete syntax
- Changes to abstract syntax
- What representation `null` will have as a value at runtime, what
instructions to generate for the new abstract syntax
- How this will interact with existing features and values from Cobra, and if
any existing cases need to change to accommodate `null`

Note that there isn't an objective correct answer to some of these, the goal
is to demonstrate that you've though through the decisions that need to be
made to add this new value and the consequences of doing so.

## Adding New Expressions – Sequencing, Variable Mutation, and While Loops

_(24 points; write no more than 2 pages)_

The languages we've implemented so far have not had any notion of variable
_assignment_ (just variable declaration). In addition, every function's body
has been a single expression, with no notion of executing a list of
expressions in order. Finally, we have recursion, but no loops.

Write a proposal to add the following features to Cobra:

- A way to write a sequence of expressions that evaluate in order
- A way to update variables to a new value
- A way to implement while loops

For each, identify:

- Changes to concrete syntax
- Changes to abstract syntax
- New well-formedness errors
- What instructions should be generated for each

You can implement it if you want to make sure you're on the right track, but
don't hand in code. Instead, your write-up should be broken down by the
4-point breakdown suggested above, once for each feature, using examples.


## Turnin

You must turn in a PDF for your submission on Gradescope to the `written1`
assignment. You should have question 1 on the first page, question 2 on the
section page, and question 3 on the subsequent pages.
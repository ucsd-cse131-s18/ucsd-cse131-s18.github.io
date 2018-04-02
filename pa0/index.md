---
layout: page
title: "PA0 – OCaml and Compiler Warmup"
doodle: "/doodle.png"
---

# PA0 – OCaml and Compiler Warmup


## OCaml Basics

We will use three programming languages in this course: OCaml, C (not C++), and
x86 assembly.  You should all have some background in C and some assembly
language, and the C we use won't be surprising.  Most of you should have some
background in programming in a functional style, which is predominantly how
we'll use OCaml.

This writeup serves as both a reference for some of the OCaml topics we'll need
in the course, and your first assignment.  You should do all the numbered
@bold{Exercises} throughout the document for your first warmup assignment, due
@emph{Tuesday, April 10} by 11:59PM.

## Setup

OCaml is installed on the ACMS machines (you can go to
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


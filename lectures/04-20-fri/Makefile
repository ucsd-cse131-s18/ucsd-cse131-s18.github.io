compile: compile.ml
	ocamlfind ocamlc -o compile -thread -package oUnit -package sexplib -linkpkg -g compile.ml

%.run: %.o main.c
	gcc -g -m32 -o $@ main.c $<

%.o: %.s
	nasm -f macho -o $@ $<

%.s: %.int compile
	./compile $< > $@


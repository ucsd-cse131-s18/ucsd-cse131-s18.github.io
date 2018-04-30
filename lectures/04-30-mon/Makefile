compile: compile_tail.ml
	ocamlfind ocamlc -o compile -thread -package oUnit -package sexplib -package str -linkpkg -g compile_tail.ml

%.run: %.o main.c compile
	gcc -g -m32 -Wl,-no_pie -o $@ main.c $<

%.o: %.s compile
	nasm -f macho -o $@ $<

%.s: %.int compile
	./compile $< > $@


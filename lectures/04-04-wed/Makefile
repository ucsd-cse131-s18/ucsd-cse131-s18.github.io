.PHONY=test

test: test.run
	./test.run

test.run: lec.ml test.ml
	ocamlfind ocamlc -o test.run -package oUnit -linkpkg -g lec.ml test.ml



open Sexplib.Sexp
module Sexp = Sexplib.Sexp

(*
expr := <number>
     |  (<op> <expr>)
     |  (let (<name> <expr>) <expr>)
     |  (+ <expr> <expr>)

op   := inc | dec
*)

type op =
  | Inc
  | Dec

type expr =
  | ENum of int
  | EBool of bool
  | EOp of op * expr
  | EId of string
  | ELet of string * expr * expr
  | EPlus of expr * expr

let int_of_string_opt s =
  try
    Some(int_of_string s)
  with
    Failure _ -> None

let rec sexp_to_expr (se : Sexp.t) : expr =
  match se with
    | Atom("true") -> EBool(true)
    | Atom("false") -> EBool(false)
    | Atom(s) ->
      (match int_of_string_opt s with
        | None -> EId(s)
        | Some(i) -> ENum(i))
    | List(sexps) ->
      match sexps with
        | [Atom("inc"); arg] -> EOp(Inc, sexp_to_expr arg)
        | [Atom("dec"); arg] -> EOp(Dec, sexp_to_expr arg)
        | [Atom("+"); arg1; arg2] -> EPlus(sexp_to_expr arg1, sexp_to_expr arg2)
        | [Atom("let"); List([Atom(name); e1]); e2] ->
          ELet(name, sexp_to_expr e1, sexp_to_expr e2)
        | _ -> failwith "Parse error"

let parse (s : string) : expr =
  sexp_to_expr (Sexp.of_string s)

open Printf

let stackloc i = (i * 4)
let stackval i = sprintf "[esp - %d]" (stackloc i)
type tenv = (string * int) list

let rec find (env : tenv) (x : string) : int option =
  match env with
    | [] -> None
    | (y, i)::rest ->
      if y = x then Some(i) else find rest x


let rec e_to_is (e : expr) (si : int) (env : tenv) =
  match e with
    | ENum(i) -> [sprintf "mov eax, %d" (i * 2 + 1)]
    | EBool(true) -> ["mov eax, 0xFFFFFFFE"]
    | EBool(false) -> ["mov eax, 0x7FFFFFFE"]
    | EPlus(e1, e2) ->
      let e1is = e_to_is e1 si env in
      let e2is = e_to_is e2 (si + 1) env in
      e1is @
      [sprintf "mov %s, eax" (stackval si)] @
      e2is @
       (* Check that the right-hand operand is a number *)
      [sprintf "mov %s, eax" (stackval (si + 1));
       "and eax, 1";
       "cmp eax, 1";
       "jne error"; (* Jump to code that can call a C function and exit *)
       sprintf "mov eax, %s" (stackval si);
       sprintf "add eax, %s" (stackval (si + 1));
       sprintf "sub eax, 1"
       ]








    | EId(x) ->
      (match find env x with
        | None -> failwith "Unbound id"
        | Some(i) ->
          [sprintf "mov eax, [esp - %d]" (stackloc i)])
    | ELet(x, v, body) ->
      let vis = e_to_is v si env in
      let bis = e_to_is body (si + 1) ((x,si)::env) in
      vis @
      [sprintf "mov [esp - %d], eax" (stackloc si)] @
      bis
    | EOp(op, e) ->
      let arg_exprs = e_to_is e si env in
      match op with
        | Inc -> arg_exprs @ ["add eax, 2"]
        | Dec -> arg_exprs @ ["sub eax, 2"]


(* Compiles a source program string to an x86 string *)
let compile (program : string) : string =
  let ast = parse program in
  let instrs = e_to_is ast 1 [] in 
  let instrs_str = (String.concat "\n" instrs) in
  sprintf "
section .text
global our_code_starts_here
error:
  ; CALL A C FUNCTION CALLED print_error_and_exit
our_code_starts_here:
  %s
  ret\n" instrs_str

let () =
  let input_file = (open_in (Sys.argv.(1))) in
  let input_program = (input_line input_file) in
  let program = (compile input_program) in
  printf "%s\n" program;;



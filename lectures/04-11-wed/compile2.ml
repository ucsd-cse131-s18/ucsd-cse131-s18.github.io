
open Sexplib.Sexp
module Sexp = Sexplib.Sexp

(*
expr := <number>
     |  (<op> <expr>)
     |  (let (<name> <expr>) <expr>)

op   := inc | dec
*)

type op =
  | Inc
  | Dec

  type expr =
    | ENum of int
    | EOp of op * expr
    (* Add the case for ELet! *)




  let rec sexp_to_expr (se : Sexp.t) : expr =
    match se with
      | Atom(s) ->




      | List(sexps) ->
        match sexps with
          | [Atom("inc"); arg] -> EOp(Inc, sexp_to_expr arg)
          | [Atom("dec"); arg] -> EOp(Dec, sexp_to_expr arg)
            (* Add the case for ELet! *)




        | _ -> failwith "Parse error"

let parse (s : string) : expr =
  sexp_to_expr (Sexp.of_string s)

open Printf

(* FILL the ELet case and anything else for the header! *)

let rec expr_to_instrs 
  match e with

    | EId(x) -> ...
    | ELet(x, val_for_x, body) -> ...







    | ENum(i) -> [sprintf "mov eax, %d" i]
    | EOp(op, e) ->
      let arg_exprs = expr_to_instrs e                      in
      match op with
        | Inc -> arg_exprs @ ["add eax, 1"]
        | Dec -> arg_exprs @ ["sub eax, 1"]
    




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
  | EId of string
  | ELet of string * expr * expr

let rec sexp_to_expr (se : Sexp.t) : expr =
  match se with
    | Atom(s) ->
      (match string_of_int_opt s with
        | None -> EId(s)
        | Some(i) -> ENum(i))
    | List(sexps) ->
      (match sexps with
        | [Atom("inc"); arg] -> EOp(Inc, sexp_to_expr arg)
        | [Atom("dec"); arg] -> EOp(Dec, sexp_to_expr arg)
        | [Atom("let"); [Atom(name); e1]; e2] ->
          ELet(name, e1, e2))
      | _ -> failwith "Parse error"

let parse (s : string) : expr =
  sexp_to_expr (Sexp.of_string s)

open Printf

let stackloc i = (i * 4)

let rec expr_to_instrs (e : expr) (si : int) (env : tenv) =
  match e with
    | EId(x) ->
      (match find env x with
        | None -> failwith "Unbound id"
        | Some(si) -> [sprintf "mov eax, [esp - %s]" (stackloc i)])
    | ELet(x, x_expr, body) ->
      let x_instrs = compile x_expr si env in
      let body_exprs = compile body (si + 1) (x, si)::env in
      x_instrs @
      [sprintf "mov [esp-%d], eax" (stackloc si)] @
      body_exprs
    | ENum(i) -> [sprintf "mov eax, %d" i]
    | EOp(op, e) ->
      let arg_exprs = expr_to_instrs e si env in
      match op with
        | Inc -> arg_exprs @ ["add eax, 1"]
        | Dec -> arg_exprs @ ["sub eax, 1"]


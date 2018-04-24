
open Sexplib.Sexp
module Sexp = Sexplib.Sexp
open Printf


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
  | EIf of expr * expr * expr
  | ELet of string * expr * expr
  | EPlus of expr * expr
  | EApp of string * expr

type def =
  | Def of string * string * expr

type prog =
  | Prog of def list

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
        | [Atom("if"); arg1; arg2; arg3] ->
          EIf(sexp_to_expr arg1, sexp_to_expr arg2, sexp_to_expr arg3)
        | [Atom("let"); List([Atom(name); e1]); e2] ->
          ELet(name, sexp_to_expr e1, sexp_to_expr e2)
        | [Atom(name); arg] ->
          EApp(name, sexp_to_expr arg)
        | _ -> failwith (sprintf "Parse error, bad expression")

let parse_def (se : Sexp.t) : def =
  match se with
    | List([Atom("def"); List([Atom(name); Atom(arg)]); body]) ->
      Def(name, arg, sexp_to_expr body)
    | _ -> failwith "Invalid def"


let parse_program (se : Sexp.t) : prog =
  match se with
    | List(defs) -> Prog(List.map parse_def defs)
    | _ -> failwith "Invalid prog"

let parse (s : string) : prog =
  parse_program (Sexp.of_string s)

let stackloc i = (i * 4)
let stackval i = sprintf "[ebp - %d]" (stackloc i)
type tenv = (string * int) list

let rec find (env : tenv) (x : string) : int option =
  match env with
    | [] -> None
    | (y, i)::rest ->
      if y = x then Some(i) else find rest x


let repr n = (n * 2) + 1

let temp_counter = ref 0
let gen_tmp str = begin
  temp_counter := (!temp_counter) + 1;
  sprintf "%s%d" str !temp_counter
end

let rec e_to_is (e : expr) (si : int) (env : tenv) =
  match e with
    | EApp(name, arg) ->
      let after_label = gen_tmp "after_call" in
      let argis = e_to_is arg si env in
      argis @
      [
        "push ebp";
        sprintf "push %s" after_label;
        "mov ebp, esp";
        "push eax";
        sprintf "jmp %s" name;
        sprintf "%s:" after_label;
        "pop ebp";
      ]
    | ENum(i) -> [sprintf "mov eax, %d" i]
    | EBool(true) -> ["mov eax, 0"]
    | EBool(false) -> ["mov eax, 1"]
    | EPlus(e1, e2) ->
      let e1is = e_to_is e1 si env in
      let e2is = e_to_is e2 (si + 1) env in
      e1is @
      [sprintf "mov %s, eax" (stackval si)] @
      e2is @
       (* Check that the right-hand operand is a number *)
      [sprintf "mov %s, eax" (stackval (si + 1));
       sprintf "mov eax, %s" (stackval si);
       sprintf "add eax, %s" (stackval (si + 1));
       ]
    | EId(x) ->
      (match find env x with
        | None -> failwith "Unbound id"
        | Some(i) ->
          [sprintf "mov eax, [ebp - %d]" (stackloc i)])
    | ELet(x, v, body) ->
      let vis = e_to_is v si env in
      let bis = e_to_is body (si + 1) ((x,si)::env) in
      vis @
      [sprintf "mov [ebp - %d], eax" (stackloc si)] @
      bis
    | EOp(op, e) ->
      let arg_exprs = e_to_is e si env in
      (match op with
        | Inc -> arg_exprs @ ["add eax, 1"]
        | Dec -> arg_exprs @ ["sub eax, 1"])
    | EIf(cond, thn, els) ->
      let condis = e_to_is cond si env in
      let afterlabel = gen_tmp "after_if" in
      let elslabel = gen_tmp "else" in
      let thnis = e_to_is thn si env in
      let elsis = e_to_is els si env in
      condis @ [
        "cmp eax, 0";
        sprintf "je %s" elslabel;
      ] @ thnis @ [ sprintf "jmp %s" afterlabel; sprintf "%s:" elslabel ] @
      elsis @ [ sprintf "%s:" afterlabel ]

let max n m = if n > m then n else m

let rec stack_depth (e : expr) =
  match e with
    | ENum(_)
    | EBool(_)
    | EId(_) -> 0
    | ELet(x, v, body) -> (max (stack_depth v) ((stack_depth body) + 1))
    | EPlus(lhs, rhs) -> (max (stack_depth lhs) ((stack_depth rhs) + 1)) + 1
    | EOp(op, e) -> stack_depth e
    | EApp(name, arg) -> (stack_depth arg) + 1
    | EIf(cond, thn, els) ->
      max (max (stack_depth cond) (stack_depth thn)) (stack_depth els)

let compile_def (d : def) =
  match d with
    | Def(name, arg, body) ->
      let depth = stack_depth body in      
      let bodyis = e_to_is body 2 [(arg, 1)] in
      [
        sprintf "%s:" name;
        sprintf "sub esp, %d" (depth * 4);
      ]
      @ bodyis @
      [
        sprintf "mov esp, ebp";
        "ret"
      ]

let compile_prog prog =
  match prog with
    | Prog(defs) ->
      List.concat (List.map compile_def defs)


(* Read a file into a string *)
let string_of_file file_name =
  let inchan = open_in file_name in
  let buf = Bytes.create (in_channel_length inchan) in
  really_input inchan buf 0 (in_channel_length inchan);
  Bytes.to_string buf

(* Compiles a source program string to an x86 string *)
let compile (program : string) : string =
  let ast = parse ("(" ^ program ^ ")") in
  let instrs = compile_prog ast in
  let instrs_str = (String.concat "\n" instrs) in
  sprintf "
section .text
global our_code_starts_here
extern print_error_and_exit
error:
  push eax
  jmp print_error_and_exit
%s
our_code_starts_here:
  push ebp
  push after_main
  mov ebp, esp
  jmp our_main
  after_main:
  pop ebp
  ret\n" instrs_str

let () =
  let text = string_of_file (Sys.argv.(1)) in
  let program = compile text in
  printf "%s\n" program;;



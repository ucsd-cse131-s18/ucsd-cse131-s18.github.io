
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

type expr =
  | ENum of int
  | EBool of bool
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

let rec string_of_expr e =
  match e with
    | ENum(n) -> string_of_int n
    | EBool(b) -> string_of_bool b
    | EId(x) -> x
    | EIf(cond, thn, els) ->
      sprintf "(if %s %s %s)" (string_of_expr cond) (string_of_expr thn) (string_of_expr els)
    | ELet(x, e, body) ->
      sprintf "(let (%s %s) %s)" x (string_of_expr e) (string_of_expr body)
    | EPlus(e1, e2) ->
      sprintf "(+ %s %s)" (string_of_expr e1) (string_of_expr e2)
    | EApp(f, arg) ->
      sprintf "(%s %s)" f (string_of_expr arg)

let string_of_def d =
  match d with
    | Def(f, arg, body) ->
      sprintf "(def (%s %s)\n  %s)" f arg (string_of_expr body)

let string_of_prog p =
  match p with
    | Prog(defs) ->
      String.concat "\n\n" (List.map string_of_def defs)

type anf_result = (string * expr) list * expr

let rec stitch (a : anf_result) : expr =
  match a with
    | [], result -> result
    | (x, e)::binds, result -> ELet(x, e, stitch (binds, result))

let rec anf_to_bind e : anf_result =
  match e with
    | ENum(_)
    | EId(_)
    | EBool(_) -> [], e
    | EPlus(e1, e2) ->
      let binds1, result1 = anf_to_val e1 in
      let binds2, result2 = anf_to_val e2 in
      binds1 @ binds2, EPlus(result1, result2)
    | EIf(cond, thn, els) ->
      let binds_cond, res_cond = anf_to_val cond in
      binds_cond, (EIf(res_cond, stitch (anf_to_bind thn), stitch (anf_to_bind els)))
    | ELet(x, e, body) ->
      let binds, result = anf_to_bind e in
      let binds_body, result_body = anf_to_bind body in
      binds @ [(x, result)] @ binds_body, result_body
    | EApp(f, arg) ->
      let binds, result = anf_to_val arg in
      binds, (EApp(f, result))

and anf_to_val e : anf_result =
  match e with
    | ENum(_)
    | EId(_)
    | EBool(_) -> [], e
    | _ ->
      let val_id = gen_tmp "val" in
      let binds, result = anf_to_bind e in
      binds @ [(val_id, result)], EId(val_id)

let anf_def d =
  match d with
    | Def(name, arg, body) ->
      Def(name, arg, stitch (anf_to_bind body))

let anf_prog p =
  match p with
    | Prog(defs) -> Prog(List.map anf_def defs)

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
  mov eax, [esp+4]
  push ebp
  push after_main
  mov ebp, esp
  push eax
  jmp our_main
  after_main:
  pop ebp
  ret\n" instrs_str

let () =
  let text = string_of_file (Sys.argv.(1)) in
  let ast = parse ("(" ^ text ^ ")") in
  let anfed = anf_prog ast in
  let program = compile text in begin
  printf "%s\n" (string_of_prog anfed);
  printf "%s\n" program;
  end;;



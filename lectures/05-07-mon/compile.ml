
open Sexplib.Sexp
module Sexp = Sexplib.Sexp
open Printf

type expr =
  | ENum of int
  | EBool of bool
  | EId of string
  | EIf of expr * expr * expr
  | ELet of string * expr * expr
  | EPlus of expr * expr
  | ELess of expr * expr
  | EMinus of expr * expr
  | EEq of expr * expr
  | EApp of string * expr
  | EApp2 of string * expr * expr
  | EPair of expr * expr
  | EFst of expr
  | ESnd of expr

type def =
  | Def of string * string * expr
  | Def2 of string * string * string * expr

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
        | [Atom("-"); arg1; arg2] -> EMinus(sexp_to_expr arg1, sexp_to_expr arg2)
        | [Atom("<"); arg1; arg2] -> ELess(sexp_to_expr arg1, sexp_to_expr arg2)
        | [Atom("=="); arg1; arg2] -> EEq(sexp_to_expr arg1, sexp_to_expr arg2)
        | [Atom("if"); arg1; arg2; arg3] ->
          EIf(sexp_to_expr arg1, sexp_to_expr arg2, sexp_to_expr arg3)
        | [Atom("let"); List([Atom(name); e1]); e2] ->
          ELet(name, sexp_to_expr e1, sexp_to_expr e2)
        | [Atom("pair"); elt1; elt2] ->
          EPair(sexp_to_expr elt1, sexp_to_expr elt2)
        | [Atom("fst"); elt] -> EFst(sexp_to_expr elt)
        | [Atom("snd"); elt] -> ESnd(sexp_to_expr elt)
        | [Atom(name); arg] ->
          EApp(name, sexp_to_expr arg)
        | [Atom(name); arg1; arg2] ->
          EApp2(name, sexp_to_expr arg1, sexp_to_expr arg2)
        | _ -> failwith (sprintf "Parse error, bad expression")

let parse_def (se : Sexp.t) : def =
  match se with
    | List([Atom("def"); List([Atom(name); Atom(arg)]); body]) ->
      Def(name, arg, sexp_to_expr body)
    | List([Atom("def"); List([Atom(name); Atom(arg1); Atom(arg2)]); body]) ->
      Def2(name, arg1, arg2, sexp_to_expr body)
    | _ -> failwith "Invalid def"


let parse_program (se : Sexp.t) : prog =
  match se with
    | List(defs) -> Prog(List.map parse_def defs)
    | _ -> failwith "Invalid prog"

let parse (s : string) : prog =
  parse_program (Sexp.of_string s)

let stackloc i = (i * 4)
let stackval i = sprintf "dword [ebp - %d]" (stackloc i)
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
    | EApp2(name, arg1, arg2) ->
      let after_label = gen_tmp "after_call" in
      let arg1is = e_to_is arg1 si env in
      let arg2is = e_to_is arg2 (si + 1) env in
      let init = [
          "push ebp";
          sprintf "push %s" after_label;
        ] in
      let after = [ sprintf "%s:" after_label; "pop ebp"] in
      arg1is @ [ sprintf "mov %s, eax" (stackval si) ]  @
      arg2is @ [ sprintf "mov %s, eax" (stackval (si + 1)) ] @
      init @
      [
        sprintf "mov eax, %s" (stackval si); "push eax";
        sprintf "mov eax, %s" (stackval (si + 1)); "push eax";
        "mov ebp, esp";
        "add ebp, 8";
        sprintf "jmp %s" name;
      ] @
      after

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
    | EBool(true) -> ["mov eax, 1"]
    | EBool(false) -> ["mov eax, 0"]
    | ELess(e1, e2) ->
      let e1is = e_to_is e1 si env in
      let e2is = e_to_is e2 (si + 1) env in
      e1is @
      [sprintf "mov %s, eax" (stackval si)] @
      e2is @
      [sprintf "mov %s, eax" (stackval (si + 1));
       sprintf "mov eax, %s" (stackval si);
       sprintf "sub eax, %s" (stackval (si + 1));
       sprintf "shr eax, 31"
       ]
    | EMinus(e1, e2) ->
      let e1is = e_to_is e1 si env in
      let e2is = e_to_is e2 (si + 1) env in
      e1is @
      [sprintf "mov %s, eax" (stackval si)] @
      e2is @
      [sprintf "mov %s, eax" (stackval (si + 1));
       sprintf "mov eax, %s" (stackval si);
       sprintf "sub eax, %s" (stackval (si + 1));
       ]
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
    | EEq(e1, e2) ->
      let e1is = e_to_is e1 si env in
      let e2is = e_to_is e2 (si + 1) env in
      let t = gen_tmp "true" in
      e1is @
      [sprintf "mov %s, eax" (stackval si)] @
      e2is @
      [
      sprintf "cmp eax, %s" (stackval si);
      "mov eax, 1";
      sprintf "je %s" t;
      "mov eax, 0";
      sprintf "%s:" t
      ]
    | EId(x) ->
      (match find env x with
        | None -> failwith ("Unbound id " ^ x)
        | Some(i) ->
          [sprintf "mov eax, [ebp - %d]" (stackloc i)])
    | ELet(x, v, body) ->
      let vis = e_to_is v si env in
      let bis = e_to_is body (si + 1) ((x,si)::env) in
      vis @
      [sprintf "mov [ebp - %d], eax" (stackloc si)] @
      bis
| EPair(f, s) ->
  let fis = e_to_is f si env in
  let sis = e_to_is s (si + 1) env in
  fis @ [sprintf "mov %s, eax" (stackval si)] @
  sis @ [sprintf "mov %s, eax" (stackval (si + 1))] @
  [
    sprintf "mov eax, %s" (stackval si);
    sprintf "mov dword [ebx], eax";
    sprintf "mov eax, %s" (stackval (si + 1));
    sprintf "mov dword [ebx + 4], eax";
    sprintf "mov eax, ebx";
    sprintf "add ebx, 8";
  ]
| EFst(e) ->
  let tis = e_to_is e si env in
  tis @ [ sprintf "mov eax, [eax]" ]
| ESnd(e) ->
  let tis = e_to_is e si env in
  tis @ [ sprintf "mov eax, [eax + 4]" ]
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
    | EPlus(lhs, rhs)
    | EMinus(lhs, rhs)
    | ELess(lhs, rhs)
    | EEq(lhs, rhs) -> (max (max (stack_depth lhs) ((stack_depth rhs) + 1)) 2)
    | EApp(name, arg) -> (max (stack_depth arg) 1)
    | EApp2(name, arg1, arg2) -> (max (max (stack_depth arg1) ((stack_depth arg2) + 1)) 2)
    | EIf(cond, thn, els) ->
      max (max (stack_depth cond) (stack_depth thn)) (stack_depth els)
    | EPair(lhs, rhs) -> (max (max (stack_depth lhs) ((stack_depth rhs) + 1)) 2)
    | EFst(arg) -> stack_depth arg
    | ESnd(arg) -> stack_depth arg

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
    | Def2(name, arg1, arg2, body) ->
      let depth = stack_depth body in      
      let bodyis = e_to_is body 3 [(arg1, 1); (arg2, 2)] in
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
  mov ebx, [esp+8]
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
  let program = compile text in
  printf "%s\n" program;;



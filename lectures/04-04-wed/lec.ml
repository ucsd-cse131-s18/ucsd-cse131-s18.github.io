open Printf

(* Back row tell me when you can read this well *)

let max (n : int) (m : int) : int =
  if m > n then
    m
  else
    n
;;

(*
   (max 4 10)
=> (if 10 > 4 then 10 else 4)
=> (if true then 10 else 4)
=> 10
*)

(*
(printf "%d\n" (max 4 10));

(max (max 3 2) 5);
*)

(* What is the next step? *)

(*

A: (max (if 2 > 3 then 2 else 3) 5);
B: (if 5 > (max 3 2) then 5 else (max 3 2))
C: It doesn't matter, they both make sense

*)


(* sum_upto, takes a number n and
produces sum of 1..n *)
let rec sum_upto (n : int) : int =
  if n = 1 then 1
  else n + (sum_upto (n - 1))
;;

(printf "%d\n" (sum_upto 4));


(* Call a no-arg function? 

  (f ())
*)


(* What about mutually recursive? *)
let rec f = 
  ... g ...

and g = 
  ... f ...








open OUnit2
open Lec

let t_string name value expected = name>::
  (fun _ -> assert_equal expected value ~printer:(fun x -> x))

let t_int name value expected = name>::
  (fun _ -> assert_equal expected value ~printer:string_of_int)

let suite =
"suite">:::
 [

 t_int "max_4_5" (max 4 5) 5;

 t_int "sum_4" (sum_upto 4) 10;

 ]
;;

run_test_tt_main suite

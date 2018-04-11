type bst =
  | Leaf
  | Node of string * bst * bst

let bst1 = Node("c", Node("a", Leaf, Leaf), Node("d", Leaf, Leaf))
let bst2 = Node("e",
  Leaf,
  Node("g", Node("f", Leaf, Leaf), Node("h", Leaf, Leaf)))

let rec contains (b : bst) (v : string) : bool =
  match b with
    | Leaf -> false
    | Node(k, left, right) ->
      (v = k) || (contains left v) || (contains right v)

EXAMPLE:

    (contains bst1 "a")

=>  (contains (Node("c", Node("a", Leaf, Leaf), Node("d", Leaf, Leaf))) "a")

=>  match (Node("c", Node("a", Leaf, Leaf), Node("d", Leaf, Leaf))) with
      | Leaf -> false
      | Node(k, left, right) ->
        ("a" = k) || (contains left "a") || (contains right "a")

(* match inspects the value and substitutes its pieces for the names.
  Here, that's:
    k => "c"
    left => Node("a", Leaf, Leaf)
    right => Node("d", Leaf, Leaf)
  *)

=>  ("a" = "c") ||
    (contains (Node("a", Leaf, Leaf)) "a") ||
    (contains (Node("d", Leaf, Leaf)) "a")

=>  false ||
    (contains (Node("a", Leaf, Leaf)) "a") ||
    (contains (Node("d", Leaf, Leaf)) "a")

=>  (contains (Node("a", Leaf, Leaf)) "a") ||
    (contains (Node("d", Leaf, Leaf)) "a")

=>  (match (Node("a", Leaf, Leaf)) with
      | Leaf -> false
      | Node(k, left, right) ->
        (v = k) || (contains left v) || (contains right v)) ||
    (contains (Node("d", Leaf, Leaf)) "a")

=>  (match (Node("a", Leaf, Leaf)) with
      | Leaf -> false
      | Node(k, left, right) ->
        ("a" = k) || (contains left "a") || (contains right "a")) ||
    (contains (Node("d", Leaf, Leaf)) "a")

=>  (("a" = "a") || (contains Leaf "a") || (contains Leaf "a")) ||
    (contains (Node("d", Leaf, Leaf)) "a")

=>  (true || (contains Leaf "a") || (contains Leaf "a")) ||
    (contains (Node("d", Leaf, Leaf)) "a")
=>  true ||
    (contains (Node("d", Leaf, Leaf)) "a")
=>  true


(* You implement insert, which takes a bst and a value and returns
   a bst that contains that value *)
  


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
      if (k = v) then true
      else if (compare k v) < 0 then
        contains right v
      else
        contains left v

(* insert : bst, string -> bst *)
(* insert string at the right place in bst order
(no balancing) *)

let rec insert (b : bst) (v : string) : bst =
  match b with
    | Leaf -> Node(v, Leaf, Leaf)
    | Node(k, left, right) ->
      if (k = v) then b
      else if (compare k v) < 0 then
        Node(k, left, insert right v)
      else
        Node(k, insert left v, right)



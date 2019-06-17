let (>>|) xs f = List.map f xs

let split n xs =
  let rec go n ys = function
  | [] -> List.rev ys, []
  | x :: xs -> if n = 0 then List.rev ys, xs
  else go (n-1) (x :: ys) xs
  in go n [] xs

let take xs n = match split xs n with (ys, _) -> ys

let take_while p xs =
  let rec go xs k = match xs with
  | [] -> k []
  | x :: xs -> if p x then go xs (fun ys -> k @@ x :: ys) else k [] in
  go xs Fun.id

let drop_while p xs =
  let rec go xs = match xs with
  | [] -> []
  | x :: xs' -> if p x then go xs' else xs in
  go xs

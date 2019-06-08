open Printf

type 'a cont = 'a -> string

let tag t: 'a cont -> 'a cont = fun k x -> sprintf "<%s>%s</%s>" t (k x) t
let seq xs: 'a cont = fun a ->
  String.concat "" @@ List.rev @@ List.fold_left (fun ys k' -> k' a :: ys) [] xs
let text t: 'a cont = fun _ -> t

let html = fun x -> seq [text "<!DOCTYPE html>"; tag "html" x]
let body = tag "body"
let head = tag "head"
let title t: unit cont = tag "title" (text t)

let index = html @@ seq [
  head @@ title "rootmos' what-nots";
  body @@ seq [text "fu"; text "bar"];
]

let () = print_endline (index ())

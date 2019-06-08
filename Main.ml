open Printf

let tag t k x = sprintf "<%s>%s</%s>" t (k x) t

let html = tag "html"
let body = tag "body"

let text t () = t

let index = html @@ body @@ text "lol"

let () = print_endline (index ())

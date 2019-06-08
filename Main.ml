open Printf

type 'a cont = 'a -> string

let tag t: 'a cont -> 'a cont = fun k x -> sprintf "<%s>%s</%s>" t (k x) t
let seq xs: 'a cont = fun a ->
  String.concat "" @@ List.rev @@ List.fold_left (fun ys k' -> k' a :: ys) [] xs
let text t: 'a cont = fun _ -> t
let noop: 'a cont = text ""

let html x = seq [text "<!DOCTYPE html>"; tag "html" x]
let body x =  tag "body" x
let head x = tag "head" x
let p x = tag "p" x
let h1 x = tag "h1" x
let title t: unit cont = tag "title" (text t)

let load_file f =
  let ic = open_in f in
  let n = in_channel_length ic in
  let s = Bytes.create n in
  really_input ic s 0 n;
  close_in ic;
  s

let write_file filename s =
  let oc = open_out filename in
  output_string oc s;
  close_out oc

let img fn alt: 'a cont = fun _ ->
  sprintf "<img src=\"data:%s;base64,%s\" alt=\"%s\"/>"
    (Magic_mime.lookup fn)
    (Base64.encode_exn @@ Bytes.to_string @@ load_file fn)
    alt

let js_src url = fun _ ->
  sprintf "<script type=\"text/javascript\" src=\"%s\"></script>" url

let live_reload = js_src "http://livejs.com/live.js"

let local = match Sys.getenv_opt "LOCAL" with
  | Some _ -> true
  | None -> false

let index = html @@ seq [
  head @@ seq [
    title "rootmos' what-nots";
    if local then live_reload else noop;
  ];
  body @@ seq [
    img "rootmos.jpg" "rootmos";
    h1 @@ text "rootmos' what-nots";
  ]
]

let () = write_file "index.html" (index ())

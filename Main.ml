open Printf

let (>>|) xs f = List.map f xs
let mks ?(delim = "") = function
  | [] -> ""
  | x :: xs -> List.fold_left (fun x y -> x ^ delim ^ y) x xs

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
let ul is x = tag "ul" (seq @@ List.map (tag "li") is) @@ x
let ol is x = tag "ol" (seq @@ List.map (tag "li") is) @@ x

let a href = fun k x -> sprintf "<a href=\"%s\">%s</a>" href (k x)

let load_file f =
  let ic = open_in f in
  let s = really_input_string ic (in_channel_length ic) in
  close_in ic; s

let write_file filename s =
  let oc = open_out filename in
  output_string oc s;
  close_out oc

let img fn alt: 'a cont = fun _ ->
  sprintf "<img src=\"data:%s;base64,%s\" alt=\"%s\"/>"
    (Magic_mime.lookup fn)
    (Base64.encode_exn @@ load_file fn)
    alt

let js_src url = fun _ ->
  sprintf "<script type=\"text/javascript\" src=\"%s\"></script>" url

let css ls = tag "style" @@ text
  ((mks ~delim:";" ls) |> String.to_seq |> Seq.filter ((<>) ' ') |> String.of_seq)

let live_reload = js_src "http://livejs.com/live.js"

let local = Sys.getenv_opt "LOCAL" |> Option.is_some

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

type post = { url: string; lines: string list; title: string; html: string }
let posts_path = "../hugo/content/post"
let static_path = "../hugo/static"

let mk_post fn =
  let content = posts_path ^ "/" ^ fn |> load_file in
  let lines = String.split_on_char '\n' content in
  let hs = mks ~delim:"\n" @@ take_while ((<>) "---") @@ List.tl @@ drop_while ((<>) "---") lines
  and bs = mks ~delim:"\n" @@ List.tl @@ drop_while ((<>) "---") @@ List.tl @@ drop_while ((<>) "---") lines in
  let props = match Yaml.of_string_exn hs with `O pp -> pp | _ -> failwith "expected object" in
  let prop p = match List.find (fun (k, _) -> k = p) props with
  (_, `String s) -> s | _ -> failwith (p ^ " wrong type") in
  let title = prop "title" in
  let md = Omd.of_string bs in
  let md = md |> Omd_representation.visit @@ function
    | Omd_representation.Img (alt, src, title) ->
        let src = static_path ^ src in
        Omd_representation.Raw (img src title ()) :: [] |> Option.some
    | Omd_representation.Text "{{< toc >}}" -> Omd.toc md |> Option.some
    | _ -> None in
  let html = Omd.to_html md in
  let url = (Filename.chop_suffix fn ".markdown") ^ ".html" in
  { url; lines; title; html }

let posts = Sys.readdir posts_path |> Array.to_list >>| mk_post

let style = css [
  "a, a:visited { color: blue; text-decoration: none; }";
]

let page subtitle b = () |> html @@ seq [
  head @@ seq [
    title @@ "rootmos' what-nots" ^ Option.fold ~some:((^) " | ") ~none:"" subtitle;
    if local then live_reload else noop;
    style;
  ];
  body @@ seq [
    h1 @@ text @@ Option.fold ~some:Fun.id ~none:"rootmos' what-nots" subtitle;
    b
  ]
]

let index = page None @@ seq [
  img "rootmos.jpg" "rootmos";
  posts >>| (fun { title; url } -> a url @@ text title) |> ul;
]

let () =
  write_file "index.html" index;
  posts |> List.iter @@ fun { url; html; title } ->
    write_file url @@ page (Some title) (text html)

open Printf
open Common
open CamomileLibraryDefault

let url_escape_string s: string =
  let b = Camomile.UTF8.Buf.create 0 in
  let f c = let cp = CamomileLibrary.UChar.code c in
    if cp > 0 && cp < 0x7f then Camomile.UTF8.Buf.add_char b c
    else
      let b' = Camomile.UTF8.Buf.create 0 in
      Camomile.UTF8.init 1 (fun _ -> c) |> Camomile.UTF8.Buf.add_string b';
      Camomile.UTF8.Buf.contents b' |> String.iter (fun c -> c |>
        Char.code |> sprintf "%%%.2X" |> Camomile.UTF8.Buf.add_string b
      )
  in Camomile.UTF8.iter f s; Camomile.UTF8.Buf.contents b

let html_escape_string s =
  let f = function
    | '&' -> "&amp;"
    | c -> String.make 1 c
  in String.to_seq s |> Seq.map f |> Seq.fold_left (^) ""

type 'a t = 'a -> string

let tag t: 'a t -> 'a t = fun k x -> sprintf "<%s>%s</%s>" t (k x) t
let seq xs: 'a t = fun a ->
  String.concat "" @@ List.rev @@ List.fold_left (fun ys k' -> k' a :: ys) [] xs
let text t: 'a t = fun _ -> t
let noop: 'a t = fun x -> text "" x

let html x = seq [text "<!DOCTYPE html>"; tag "html" x]
let body x =  tag "body" x
let head x = tag "head" x
let p x = tag "p" x
let h1 x = tag "h1" x
let h2 x = tag "h2" x
let title t = tag "title" (text t)
let ul is x = tag "ul" (is >>| tag "li" |> seq) x
let ol is x = tag "ol" (is >>| tag "li" |> seq) x
let audio ?(id="") src = text @@
  sprintf "<audio%s controls preload=\"metadata\" class=\"sound\"><source src=\"%s\"/></audio>"
  (if id <> "" then sprintf " id=\"%s\"" id else "")
  (url_escape_string src |> html_escape_string)
let video src = text @@
  sprintf "<video controls preload=\"metadata\" class=\"video\"><source src=\"%s\"/></video>"
  (url_escape_string src |> html_escape_string)
let script s = text s |> tag "script"
let table cs x = let tr cs = tag "tr" (cs >>| tag "td" |> seq) in
  tag "table" (cs >>| tr |> seq) x
let div ?(id="") ?(cls="") = fun k x ->
  let c = if cls <> "" then sprintf " class=\"%s\"" cls else "" in
  let i = if id <> "" then sprintf " id=\"%s\"" id else "" in
  sprintf "<div%s%s>%s</div>" c i (k x)
let span ?(cls="") = fun k x ->
  if cls <> "" then sprintf "<span class=\"%s\">%s</span>" cls (k x)
  else sprintf "<span>%s</span>" (k x)

let a href = fun k x -> sprintf "<a href=\"%s\">%s</a>"
  (url_escape_string href |> html_escape_string) (k x)

let img ?(embedd=true) ?(cls="") fn alt = fun _ ->
  let c = if cls <> "" then sprintf " class=\"%s\"" cls else "" in
  let a = if alt <> "" then sprintf " title=\"%s\" alt=\"%s\"" alt alt else "" in
  if embedd then sprintf "<img src=\"data:%s;base64,%s\" %s%s/>"
    (Magic_mime.lookup fn) (Base64.encode_exn @@ Utils.load_file fn) a c
  else sprintf "<img src=\"%s\" %s%s/>" fn a c

let svg ?(cls = "") fn =
  let s = Utils.load_file fn in
  let s = match cls with "" -> s | _ ->
    Str.replace_first (Str.regexp "svg") (sprintf "svg class=\"%s\"" cls) s in
  text s

let js_src url = fun _ ->
  sprintf "<script type=\"text/javascript\" src=\"%s\"></script>" url

let minimize_css s =
  let s = Str.global_replace (Str.regexp "\n") "" s in
  let s = Str.global_replace (Str.regexp ":[ \t]+") ":" s in
  let s = Str.global_replace (Str.regexp "[ \t]*{[ \t]*") "{" s in
  let s = Str.global_replace (Str.regexp "[ \t]*}[ \t]*") "}" s in
  let s = Str.global_replace (Str.regexp "[ \t]*;[ \t]*") ";" s
  in s

let css ls = let body = ls |> String.concat "" |> minimize_css in
  text @@ sprintf "<style type=\"text/css\">%s</style>" body

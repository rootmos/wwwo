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
let audio src = text @@
  sprintf "<audio controls preload=\"none\" class=\"sound\"><source src=\"%s\"/></audio>"
  (url_escape_string src |> html_escape_string)
let script s = text s |> tag "script"
let table cs x = let tr cs = tag "tr" (cs >>| tag "td" |> seq) in
  tag "table" (cs >>| tr |> seq) x
let div ?(cls = "") = fun k x ->
  if cls <> "" then sprintf "<div class=\"%s\">%s</div>" cls (k x)
  else sprintf "<div>%s</div>" (k x)
let span ?(cls = "") = fun k x ->
  if cls <> "" then sprintf "<span class=\"%s\">%s</span>" cls (k x)
  else sprintf "<span>%s</span>" (k x)

let a href = fun k x -> sprintf "<a href=\"%s\">%s</a>"
  (url_escape_string href |> html_escape_string) (k x)

let img ?(cls = "") fn alt = fun _ ->
  if cls <> "" then
    sprintf "<img src=\"data:%s;base64,%s\" title=\"%s\" alt=\"%s\" class=\"%s\"/>"
      (Magic_mime.lookup fn)
      (Base64.encode_exn @@ Utils.load_file fn)
      alt alt cls
  else
    sprintf "<img src=\"data:%s;base64,%s\" title=\"%s\" alt=\"%s\"/>"
      (Magic_mime.lookup fn)
      (Base64.encode_exn @@ Utils.load_file fn)
      alt alt

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

open Printf
open Common

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
let audio src = text @@ sprintf "<audio controls preload=\"none\" class=\"sound\"><source src=\"%s\"/></audio>" src
let script s = text s |> tag "script"
let table cs x = let tr cs = tag "tr" (cs >>| tag "td" |> seq) in
  tag "table" (cs >>| tr |> seq) x
let div ?(cls = "") = fun k x ->
  if cls <> "" then sprintf "<div class=\"%s\">%s</div>" cls (k x)
  else sprintf "<div>%s</div>" (k x)
let span ?(cls = "") = fun k x ->
  if cls <> "" then sprintf "<span class=\"%s\">%s</span>" cls (k x)
  else sprintf "<span>%s</span>" (k x)

let a href = fun k x -> sprintf "<a href=\"%s\">%s</a>" href (k x)

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

let css ls = let body = ls |> String.concat "" |>
  String.to_seq |> Seq.filter ((<>) ' ') |> String.of_seq in
  text @@ sprintf "<style type=\"text/css\">%s</style>" body

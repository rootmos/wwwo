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

let tag ?(id=None) ?(cls=None) ?(style=None) t: 'a t -> 'a t = fun k x ->
  let attrs = let open Option in [
    map (sprintf " id=\"%s\"") id;
    map (sprintf " class=\"%s\"") cls;
    map (sprintf " style=\"%s\"") style;
  ] >>| to_list |> List.flatten |> String.concat "" in
  sprintf "<%s%s>%s</%s>" t attrs (k x) t
let seq xs: 'a t = fun a ->
  String.concat "" @@ List.rev @@ List.fold_left (fun ys k' -> k' a :: ys) [] xs
let text t: 'a t = fun _ -> t
let noop: 'a t = fun x -> text "" x

let html x = seq [text "<!DOCTYPE html>"; tag "html" x]
let body x =  tag "body" x
let head x = tag "head" x
let p ?(cls=None) ?(id=None) ?(style=None) x = tag ~cls ~id ~style "p" x
let h1 x = tag "h1" x
let h2 x = tag "h2" x
let title t = tag "title" (text t)
let ul is = match is with
| [] -> noop
| _ -> tag "ul" (is >>| tag "li" |> seq)
let ol is x = tag "ol" (is >>| tag "li" |> seq) x
let audio ?(id="") src = text @@
  sprintf "<audio%s controls class=\"sound\"><source src=\"%s\"/></audio>"
  (if id <> "" then sprintf " id=\"%s\"" id else "")
  (url_escape_string src |> html_escape_string)
let video src = text @@
  sprintf "<video controls class=\"video\"><source src=\"%s\"/></video>"
  (url_escape_string src |> html_escape_string)
let canvas id width height = text @@
  sprintf "<canvas id=\"%s\" width=\"%d\" height=\"%d\" />" id width height
let table ?(widths=None) cs =
  let tr cs = cs >>| tag "td" |> seq |> tag "tr" in
  let tr' cs = match widths with None -> tr cs | Some ws ->
    List.combine cs ws >>| (fun (c, w) ->
      let style = Some (sprintf "width: %d%%" w) in tag ~style "td" c
    ) |> seq |> tag "tr" in
  let cs' = match cs with
  | [] -> []
  | c :: cs -> tr' c :: (cs >>| tr) in
  tag "table" (seq cs')
let div ?(id=None) ?(cls=None) ?(style=None) = tag ~id ~cls ~style "div"
let span ?(cls="") = fun k x ->
  if cls <> "" then sprintf "<span class=\"%s\">%s</span>" cls (k x)
  else sprintf "<span>%s</span>" (k x)

let a href = fun k x -> sprintf "<a href=\"%s\">%s</a>"
    (url_escape_string href |> html_escape_string) (k x)

let button s = fun k x ->
  sprintf "<a href=\"#\" onclick=\"%s\">%s</a>" s (k x)

let img ?(embedd=true) ?(cls=None) ?(alt=None) fn = fun _ ->
  let c = let open Option in
    map (sprintf " class=\"%s\"") cls |> value ~default:"" in
  let a = let open Option in
    map (fun a -> sprintf " title=\"%s\" alt=\"%s\"" a a) alt
    |> value ~default:"" in
  if embedd then sprintf "<img src=\"data:%s;base64,%s\" %s%s/>"
    (Magic_mime.lookup fn) (Base64.encode_exn @@ Utils.load_file fn) a c
  else sprintf "<img src=\"%s\" %s%s/>" fn a c

let svg ?(cls = "") fn =
  let s = Utils.load_file fn |> String.trim in
  let s = match cls with "" -> s | _ ->
    Str.replace_first (Str.regexp "<svg") (sprintf "<svg class=\"%s\"" cls) s in
  text s

let js_src url = fun _ ->
  sprintf "<script type=\"text/javascript\" src=\"%s\"></script>" url

let minimize_css s =
  let s = Str.global_replace (Str.regexp "\n") "" s in
  let s = Str.global_replace (Str.regexp ":[ \t]+") ":" s in
  let s = Str.global_replace (Str.regexp "[ \t]*{[ \t]*") "{" s in
  let s = Str.global_replace (Str.regexp "[ \t]*}[ \t]*") "}" s in
  let s = Str.global_replace (Str.regexp "[ \t]*;[ \t]*") ";" s in
  s

let css ls = let body = ls |> String.concat "" |> minimize_css in
  text @@ sprintf "<style type=\"text/css\">%s</style>" body

(* TODO: this is too aggressive since it doesn't respect quotes *)
let minimize_js s =
  let s = Str.global_replace (Str.regexp "\n") "" s in
  let s = Str.global_replace (Str.regexp ":[ \t]+") ":" s in
  let s = Str.global_replace (Str.regexp "[ \t]*=[ \t]*") "=" s in
  let s = Str.global_replace (Str.regexp "[ \t]*{[ \t]*") "{" s in
  let s = Str.global_replace (Str.regexp "[ \t]*}[ \t]*") "}" s in
  let s = Str.global_replace (Str.regexp "[ \t]*\\[[ \t]*") "[" s in
  let s = Str.global_replace (Str.regexp "[ \t]*\\][ \t]*") "]" s in
  let s = Str.global_replace (Str.regexp "[ \t]*,[ \t]*") "," s in
  s

let script s = text (minimize_js s) |> tag "script"

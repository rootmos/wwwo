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
let ul is x = tag "ul" (is >>| tag "li" |> seq) x
let ol is x = tag "ol" (is >>| tag "li" |> seq) x
let audio src = text @@ sprintf "<audio controls preload=\"none\" class=\"sound\"><source src=\"%s\"/></audio>" src
let script s = text s |> tag "script"
let table cs x = let tr cs = tag "tr" (cs >>| tag "td" |> seq) in
  tag "table" (cs >>| tr |> seq) x

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

type post = { url: string; lines: string list; title: string; html: string; date: string }
let posts_path = "../hugo/content/post"
let static_path = "../hugo/static"

let mk_post fn =
  let lines = posts_path ^ "/" ^ fn |> load_file |> String.split_on_char '\n' in
  let hs = mks ~delim:"\n" @@ take_while ((<>) "---")
    @@ List.tl @@ drop_while ((<>) "---") lines in
  let bs = mks ~delim:"\n" @@ List.tl @@ drop_while ((<>) "---")
    @@ List.tl @@ drop_while ((<>) "---") lines in

  let props = match Yaml.of_string_exn hs with `O pp -> pp | _ -> failwith "expected object" in
  let prop p = match List.find (fun (k, _) -> k = p) props with
  (_, `String s) -> s | _ -> failwith (p ^ " wrong type") in

  let md = Omd.of_string bs in
  let md = md |> Omd_representation.visit @@ function
    | Omd_representation.Img (alt, src, title) ->
        let src = static_path ^ src in
        Omd_representation.Raw (img src title ()) :: [] |> Option.some
    | Omd_representation.Text "{{< toc >}}" -> Omd.toc md |> Option.some
    | _ -> None

  in {
    url = (Filename.chop_suffix fn ".markdown") ^ ".html";
    lines; html = Omd.to_html md;
    title = prop "title"; date = prop "date";
  }

let posts = Sys.readdir posts_path |> Array.to_list >>| mk_post |>
  List.sort (fun { date = d } { date = d' } -> String.compare d d')

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

type sound = { title: string; url: string; date: CalendarLib.Date.t }

let parse_date s =
  try CalendarLib.Printer.Date.from_fstring "%F" s
  with Invalid_argument _ ->
  CalendarLib.Printer.Date.from_fstring "%FT%T%:z" s

let sounds =
  let fn = "sounds.json" in
  let open Yojson.Basic.Util in
  let js = Yojson.Basic.from_string ~fname:fn (load_file fn) |> to_list in
  let f j = {
    title = j |> member "title" |> to_string;
    url = j |> member "url" |> to_string;
    date = j |> member "date" |> to_string |> parse_date;
  } in
  let r = fun { title; url; date } -> [
    text title;
    text @@ CalendarLib.Printer.Date.sprint "%a, %d %b %Y" date;
    audio url
  ] in
  seq [
    (js >>| f >>| r) |> table;
    String.concat "" [
      "{const ss=document.getElementsByClassName(\"sound\");";
      "for(var s of ss){s.onplay=function(e){";
      "for(var t of ss){if(t!=e.target&&!t.paused){t.pause()}}}}}";
    ] |> script
  ] |> page (Some "Sounds")

let resolve h = Unix.getaddrinfo h ""
  [Unix.AI_FAMILY Unix.PF_INET; Unix.AI_SOCKTYPE Unix.SOCK_STREAM]
  |> function
  | { ai_addr = Unix.ADDR_INET (a, _) } :: _ -> Unix.string_of_inet_addr a |> Option.some
  | _ -> Option.none

let services = ul @@ [
  text @@ sprintf "dns.rootmos.io (%s) 53 UDP/TCP, 853 DNS over TLS"
    (Option.get @@ resolve "dns.rootmos.io");
  a "https://ip.rootmos.io" (text "ip.rootmos.io");
]

let index = page None @@ seq [
  img "rootmos.jpg" "rootmos";
  posts
    >>| (fun { title; url; date } -> a url @@ text @@ sprintf "%s (%s)" title date)
    |> ul;
  ul @@ [ a "sounds.html" (text "Sounds") ];
  services;
]

let () =
  write_file "index.html" index;
  write_file "sounds.html" sounds;
  posts |> List.iter @@ fun { url; html; title } ->
    write_file url @@ page (Some title) (text html)

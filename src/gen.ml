open Common
open Html
open Printf

let live_reload = js_src "http://livejs.com/live.js"
let tracking = seq [
  js_src "https://www.googletagmanager.com/gtag/js?id=UA-124878438-2";
  String.concat "" [
    "window.dataLayer = window.dataLayer || [];";
    "function gtag(){dataLayer.push(arguments);} gtag('js', new Date());";
    "gtag('config', 'UA-124878438-2')";
  ] |> script
]

let local = match Sys.getenv "ENV" with
| "dev" -> true
| _ -> false

type post = { url: string; lines: string list; title: string; html: string; date: string }
let posts_path = "../hugo/content/post"
let static_path = "../hugo/static"

let mk_post fn =
  let lines = posts_path ^ "/" ^ fn |> Utils.load_file
    |> String.split_on_char '\n' in
  let hs = String.concat "\n" @@ take_while ((<>) "---")
    @@ List.tl @@ drop_while ((<>) "---") lines in
  let bs = String.concat "\n" @@ List.tl @@ drop_while ((<>) "---")
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

let posts_snippet = seq [
  h2 @@ text "Posts";
  posts >>| (fun { title; url; date } ->
    a url @@ text @@ sprintf "%s (%s)" title date
  ) |> ul
]

let page ?(only_subtitle=false) subtitle b =
  let t = "rootmos' " ^ Option.fold ~some:Fun.id ~none:"what-nots" subtitle in
  () |> html @@ seq [
  head @@ seq [
    title @@ t;
    if local then live_reload else tracking;
    css [ Utils.load_file "style.css" ];
    text "<meta charset=\"UTF-8\">";
  ];
  body @@ seq [
    h1 @@ seq [
      text @@ if only_subtitle then Option.get subtitle else t;
      if Option.is_some subtitle then
        span ~cls:"subtitle" @@ a "index.html" @@ text "back" else noop
    ];
    div ~cls:"content" @@ b
  ]
]

let sounds =
  let open Sounds_t in
  let js = Sounds_j.sounds_of_string (Utils.load_file "sounds.json") in
  let s s0 s1 = Lenient_iso8601.compare s1.date s0.date in
  js |> List.sort s
and audio_player_script = String.concat "" [
  "{const ss=document.getElementsByClassName(\"sound\");";
  "for(var s of ss){s.onplay=function(e){";
  "for(var t of ss){if(t!=e.target&&!t.paused){t.pause()}}}}}";
] |> script

let sounds_page = let open Sounds_t in
  let r s = [
    text s.title;
    div ~cls:"date" @@ text @@ Lenient_iso8601.rfc822 s.date;
    audio s.url
  ] in seq [
    sounds >>| r |> table;
    audio_player_script;
  ] |> page (Some "sounds")

and sounds_snippet = let open Sounds_t in
  let r s = [
    text s.title;
    div ~cls:"date" @@ text @@ Lenient_iso8601.rfc822 s.date;
    audio s.url
  ] in seq [
    h2 @@ seq [
      text "Sounds";
      span ~cls:"subtitle" @@ a "sounds.html" @@ text "all"
    ];
    sounds |> take 5 >>| r |> table;
    audio_player_script;
  ]

let activity = let open Github_t in
  let cs = Utils.load_file "github-activity.rootmos.commits.json" |>
    Github_j.commits_of_string in
  let s c0 c1 = Lenient_iso8601.compare c1.date c0.date in
  cs |> List.sort s

let activity_page = let open Github_t in
  let r c = [
    div ~cls:"date" @@ text @@ Lenient_iso8601.rfc822 c.date;
    a c.repo_url @@ text c.repo;
    a c.url @@ text c.message;
  ] in activity >>| r |> table |> page (Some "activity")
and activity_snippet = let open Github_t in
  let r c = [
    div ~cls:"date" @@ text @@ Lenient_iso8601.rfc822 c.date;
    a c.repo_url @@ text c.repo;
    a c.url @@ text c.message;
  ] in seq [
    h2 @@ seq [
      text "Activity";
      span ~cls:"subtitle" @@ a "activity.html" @@ text "more"
    ];
    activity |> take 5 >>| r |> table;
  ]

let resolve h = Unix.getaddrinfo h ""
  [Unix.AI_FAMILY Unix.PF_INET; Unix.AI_SOCKTYPE Unix.SOCK_STREAM]
  |> function
  | { ai_addr = Unix.ADDR_INET (a, _) } :: _ -> Unix.string_of_inet_addr a |> Option.some
  | _ -> Option.none

let services_snippet = seq [
  h2 @@ seq [ text "Services"; span ~cls:"subtitle" @@ text "what I host" ];
  ul @@ [
    seq [
      text "dns.rootmos.io (";
      a "https://www.digwebinterface.com/?hostnames=google.com&type=A&ns=self&nameservers=dns.rootmos.io"
        @@ text "dig";
      text @@ sprintf ") (%s) 53 UDP/TCP, 853 DNS over TLS"
        (Option.get @@ resolve "dns.rootmos.io");
    ];
    a "https://ip.rootmos.io" (text "ip.rootmos.io");
  ]
]

let resume_snippet = seq [
  h2 @@ text "Resume";
  p @@ seq [
    (let url = "https://rootmos-static.ams3.cdn.digitaloceanspaces.com/resume-gustav-behm.pdf"
    in a url @@ text "PDF");
    text " (updated 30 Nov 2018)";
  ]
]

let social = seq [
  a "https://github.com/rootmos" @@ img ~cls:"social"
    "fa/svgs/brands/github.svg" "GitHub";
  a "https://soundcloud.com/rootmos" @@ img ~cls:"social"
    "fa/svgs/brands/soundcloud.svg" "SoundCloud";
  a "https://keybase.io/rootmos" @@ img ~cls:"social"
    "fa/svgs/brands/keybase.svg" "Keybase";
]

let md_snippet fn =
  let md = Utils.load_file fn |> Omd.of_string |> Omd_representation.visit @@ function
    | Omd_representation.H1 t -> Some (Omd_representation.H2 t :: [])
    | Omd_representation.H2 t -> Some (Omd_representation.H3 t :: [])
    | _ -> None in
  text @@ Omd.to_html md

let index = page None @@ seq [
  div ~cls:"intro" @@ seq [
    img ~cls:"avatar" "rootmos.jpg" "Rolling Oblong Ortofon Troubadouring Mystique Over Salaciousness";
    div ~cls:"slogan" @@ text "Some math, mostly programming and everything in between";
    social;
  ];
  div ~cls:"content" @@ posts_snippet;
  div ~cls:"content" @@ sounds_snippet;
  div ~cls:"content" @@ activity_snippet;
  div ~cls:"content" @@ services_snippet;
  div ~cls:"content" @@ md_snippet "projects.md";
  div ~cls:"content" @@ md_snippet "academic.md";
  div ~cls:"content" @@ resume_snippet;
]

let () =
  let webroot = Sys.getenv "WEBROOT" ^ "/" ^ Sys.getenv "ENV" in
  Utils.write_file (webroot ^ "/index.html") index;
  Utils.write_file (webroot ^ "/sounds.html") sounds_page;
  Utils.write_file (webroot ^ "/activity.html") activity_page;
  posts |> List.iter @@ fun { url; html; title } ->
    Utils.write_file (webroot ^ "/" ^ url) @@
      page ~only_subtitle:true (Some title) (text html)

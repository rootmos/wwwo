open Common
open Html
open Printf

let base_url = Env.require "BASE_URL"

let config = Page.Config.from_env ()
let pagemaker ~path =
  let canonical_url = Some (base_url ^ path) in
  Page.make ~config:config ~canonical_url

let sounds fn =
  let open Sounds_t in
  let js = Path.meta fn |>
    Utils.load_file |> Sounds_j.sounds_of_string in
  let s s0 s1 = Lenient_iso8601.compare s1.date s0.date in
  js |> List.sort s
and audio_player_script = String.concat "" [
  "{const ss=document.getElementsByClassName(\"sound\");";
  "for(var s of ss){s.onplay=function(e){";
  "for(var t of ss){if(t!=e.target&&!t.paused){t.pause()}}}}}";
] |> script

let sounds_page = let open Sounds_t in
  let r s = let id = String.sub s.sha1 0 7 in [
    text s.title;
    div ~cls:(Some "date") @@ text @@ Lenient_iso8601.rfc822 s.date;
    audio ~id s.url;
    a ("/sounds.html#" ^ id) @@ svg ~cls:"button" "fa/svgs/solid/share-alt.svg";
  ] in seq [
    p ~cls:(Some "c") @@ a "/bor19" @@ text "Best of rootmos 2019 mix";
    sounds "sounds.json" >>| r |> table ~widths:(Some [80;10;5;5]);
    audio_player_script;
  ] |> pagemaker (Subtitle "sounds")
    ~additional_css:[ Utils.load_file (Path.style "sounds.css") ]

let sounds_jam_page = let open Sounds_t in
  let r s = let id = String.sub s.sha1 0 7 in [
    text s.title;
    audio ~id s.url;
    a ("/jam.html#" ^ id) @@ svg ~cls:"button" "fa/svgs/solid/share-alt.svg";
  ] in seq [
    p ~cls:(Some "c") @@  img ~cls:(Some "cover") ~alt:(Some "jam sessions")
      (Path.image "spät.jpg");
    sounds "sounds.sessions.json" >>| r |> table ~widths:(Some [80;5;5]);
    audio_player_script;
  ] |> pagemaker (Subtitle "jam sessions")
    ~additional_css:[ Utils.load_file (Path.style "sounds.css") ]

and sounds_snippet = let open Sounds_t in
  let r s = [
    text s.title;
    div ~cls:(Some "date") @@ text @@ Lenient_iso8601.rfc822 s.date;
    audio s.url;
  ] in seq [
    h2 @@ seq [
      text "Sounds";
      span ~cls:"subtitle" @@ a "jam.html" @@ text "jam";
      span ~cls:"subtitle" @@ a "demo.html" @@ text "demo";
      span ~cls:"subtitle" @@ a "sounds.html" @@ text "all";
      span ~cls:"subtitle" @@ a "bor19/index.html" @@ text "bor19";
    ];
    sounds "sounds.json" |> take 5 >>| r |> table;
    audio_player_script;
  ]

let practice_page =
  let open Sounds_t in
  let module Dates = Map.Make(Lenient_iso8601.Date) in
  let f s = function
    | None -> Some s.length
    | Some l -> Some (l +. s.length) in
  let ss = sounds "sounds.practice.json" in
  let ds = List.fold_left (fun ds s -> Dates.update s.date (f s) ds)
    Dates.empty ss in
  let data = Dates.to_seq ds
    |> Seq.map (fun (d, s) -> let open Practice_t in {
      date =  Lenient_iso8601.Date.iso8601 d;
      minutes = (Float.round @@ s /. 6.) /. 10.;
    })
    |> List.of_seq |> Practice_j.string_of_data in
  let js = Path.js "practice.js" |> Utils.load_file in
  let r s = let id = String.sub s.sha1 0 7 in [
    text s.title;
    div ~cls:(Some "date") @@ text @@ Lenient_iso8601.rfc822 s.date;
    audio ~id s.url;
    a ("/practice.html#" ^ id) @@ svg ~cls:"button" "fa/svgs/solid/share-alt.svg";
  ] in
  seq [
    div @@ seq [
      canvas "chart" 300 100;
      script (sprintf "data = %s; %s" data js);
    ];
    div ~cls:(Some "buttons") @@ seq [
      span ~cls:"range" @@ button "render(7)" @@ text "week";
      span ~cls:"range" @@ button "render(30)" @@ text "month";
      span ~cls:"range" @@ button "render()" @@ text "all";
    ];
    ss >>| r |> table ~widths:(Some [80;10;5;5]);
    audio_player_script;
  ] |> pagemaker ~chartjs:true (Subtitle "practice")
    ~additional_css:[ Utils.load_file (Path.style "practice.css") ]

let demo_page = let open Sounds_t in
  let r s = let id = String.sub s.sha1 0 7 in [
    text s.title;
    div ~cls:(Some "date") @@ text @@ Lenient_iso8601.rfc822 s.date;
    audio ~id s.url;
    a ("/demo.html#" ^ id) @@ svg ~cls:"button" "fa/svgs/solid/share-alt.svg";
  ] in
  let ss = sounds "sounds.demo.json" in
  let l = ss >>| (fun s -> s.length) |> List.fold_left (+.) 0.0 in
  let s = Float.to_int l in
  let h = s / 3600 in
  let m = (s - 3600*h)/60 in
  let s = s - 3600*h - m*60 in
  seq [
    ss >>| r |> table ~widths:(Some [80;10;5;5]);
    div ~cls:(Some "c") @@ text @@ sprintf "Length: %.2d:%.2d:%.2d" h m s;
    audio_player_script;
  ] |> pagemaker (Subtitle "demo")
    ~additional_css:[ Utils.load_file (Path.style "sounds.css") ]

let activity = let open Github_t in
  let cs = Path.meta "github-activity.rootmos.commits.json" |>
    Utils.load_file |> Github_j.commits_of_string in
  let s c0 c1 = Lenient_iso8601.compare c1.date c0.date in
  cs |> List.sort s

let activity_page = let open Github_t in
  let r c = [
    div ~cls:(Some "date") @@ text @@ Lenient_iso8601.rfc822 c.date;
    a c.repo_url @@ text c.repo;
    a c.url @@ text c.message;
  ] in activity >>| r |> table |> pagemaker (Subtitle "activity")
and activity_snippet = let open Github_t in
  let r c = [
    div ~cls:(Some "date") @@ text @@ Lenient_iso8601.rfc822 c.date;
    a c.repo_url @@ text c.repo;
    a c.url @@ text c.message;
  ] in seq [
    h2 @@ text "Activity";
    activity |> take 10 >>| r |> table;
  ]

let twitch_snippet = let open Twitch_t in
  let vods = Path.meta "twitch.rootmos2.json" |>
      Utils.load_file |> Twitch_j.videos_of_string in
  let s v0 v1 = Lenient_iso8601.compare v1.date v0.date in
  let vods = List.sort s vods in
  let h v = div ~cls:(Some "vod") @@ seq [
    div ~cls:(Some "thumbnail") @@ a v.url @@ img_b64 v.thumbnail.mimetype v.thumbnail.base64;
    div ~cls:(Some "title") @@ a v.url @@ text v.title;
  ] in
  seq [
    h2 @@ text "Twitch highlights";
    vods >>| h |> seq |> div ~cls:(Some "highlights");
  ]

let projects_snippet =
  let open Project_t in
  let projects =
    let ps = Path.meta "projects.json" |>
      Utils.load_file |> Project_j.projects_of_string in
    let s p0 p1 = Lenient_iso8601.compare p1.last_activity p0.last_activity in
    ps |> List.sort s in
  let r p = seq [
    a p.url @@ text p.name;
    (match p.stars with None -> noop | Some 0 -> noop | Some s -> text (sprintf " ★%d" s));
    (match p.description with Some d -> text (" » " ^ d) | None -> noop);
    p.subprojects >>| (fun (s: subproject) -> seq [
      a s.url @@ text s.name;
      (match s.description with Some d -> text (" » " ^ d) | None -> noop);
    ]) |> ul;
  ]
  in seq [
    h2 @@ text "Projects";
    projects >>| r |> ul ~cls:(Some "content");
  ]

let services_snippet = seq [
  h2 @@ text "Services";
  ul @@ [
    a "https://ip.rootmos.io" (text "ip.rootmos.io");
  ]
]

let resume_snippet =
  let r = Path.meta "resume.json" |> Utils.load_file |> Resume_j.resume_of_string in
  seq [
    h2 @@ text "Resume";
    p @@ seq [
      a (Page.static "resume-gustav-behm.pdf" (* TODO should be part of the resume.json *)) @@ text "PDF";
      text @@ sprintf" (updated %s)" r.updated;
    ]
  ]

let social = seq @@ List.rev [
  a "https://github.com/rootmos" @@ svg ~cls:"social" "fa/svgs/brands/github.svg";
  a "https://git.sr.ht/~rootmos" @@ svg ~cls:"social" (Path.image "sourcehut.svg");
  a "https://keybase.io/rootmos" @@ svg ~cls:"social" "fa/svgs/brands/keybase.svg";
  a "https://twitch.tv/rootmos2" @@ svg ~cls:"social" "fa/svgs/brands/twitch.svg";
  a "https://soundcloud.com/rootmos" @@ svg ~cls:"social" "fa/svgs/brands/soundcloud.svg";
]

let md_snippet s =
  let raw = Utils.load_file s in
  let md = raw |> Omd.of_string |> Omd_representation.visit @@ function
    | Omd_representation.H1 t -> Some (Omd_representation.H2 t :: [])
    | Omd_representation.H2 t -> Some (Omd_representation.H3 t :: [])
    | _ -> None in
  text @@ Omd.to_html md

let index posts_snippet =
  let acronym = "Rolling Oblong Ortofon Troubadouring Mystique Over Salaciousness" in
  pagemaker Default ~additional_css:[ Utils.load_file (Path.style "twitch.css") ] @@ seq [
  div ~cls:(Some "intro") @@ seq [
    script @@ String.concat "" [
      "let avatar_revealed = 0;";
      "function avatar_show_hint() {";
      "  if(!avatar_revealed) {";
      "    document.getElementById('avatar-hint').style['display'] = 'block';";
      "  }";
      "}";
      "setTimeout(avatar_show_hint, 5000);";
      "let avatar_clicks = 0;";
      "function avatar_onclick() {";
      "  document.getElementById('avatar-hint').style['display'] = 'none';";
      "  const e1 = document.getElementById('avatar-explanation-1');";
      "  const e2 = document.getElementById('avatar-explanation-2');";
      "  if(avatar_clicks%4 == 0) {";
      "    e1.style['display'] = 'block';";
      "  } else if(avatar_clicks%4 == 1) {";
      "    e2.style['display'] = 'block';";
      "  } else if(avatar_clicks%4 == 2) {";
      "    e2.style['display'] = 'none';";
      "  } else {";
      "    e1.style['display'] = 'none';";
      "  }";
      "  avatar_clicks += 1;";
      "  avatar_revealed = 1;";
      "}";
    ];
    img ~cls:(Some "avatar") ~alt:(Some acronym) ~onclick:(Some "avatar_onclick()")
      (Path.image "rootmos.jpg");
    div ~cls:(Some "slogan") @@ seq [
      text "Some math, music, mostly programming and everything in between";
      div ~id:(Some "avatar-hint") ~style:(Some "display: none") @@ text "click me ⇒ ";
      div ~id:(Some "avatar-explanation-1") ~style:(Some "display: none") @@ seq [
        text acronym;
        text " ";
        a "https://knowyourmeme.com/memes/astronaut-sloth" @@ text "[?]";
      ];
      div ~id:(Some "avatar-explanation-2") ~style:(Some "display: none") @@ seq [
        text "conflation of ";
        a "https://en.wikipedia.org/wiki/Superuser" @@ text "root";
        text " and ";
        a "https://sv.wikipedia.org/wiki/Rotmos" @@ text "rotmos";
      ];
    ];
    social;
  ];
  div ~cls:(Some "content") @@ sounds_snippet;
  div ~cls:(Some "content twitch") @@ twitch_snippet;
  div ~cls:(Some "content") @@ activity_snippet;
  div ~cls:(Some "content") @@ projects_snippet;
  div ~cls:(Some "content") @@ posts_snippet;
  div ~cls:(Some "content") @@ services_snippet;
  div ~cls:(Some "content") @@ md_snippet (Path.snippet "academic.md");
  div ~cls:(Some "content") @@ resume_snippet;
]

let bor19 = seq [
  p ~cls:(Some "c") @@ img ~cls:(Some "cover") ~alt:(Some "cover")
    (Path.image "bor19-cover.jpg");
  ul [
    audio ~id:"mix" "https://rootmos-sounds.s3.eu-central-1.amazonaws.com/2019-12-23-best-of-rootmos-2019.mp3";
    a "https://www.mixcloud.com/rootmos/best-of-rootmos-2019/" @@ text "Mixcloud";
    seq [
      text "Tracks:";
      String.concat "" [
        "function seek(m, s) {";
        "const ss = document.getElementById(\"mix\");";
        "ss.currentTime = m * 60 + s; ss.play(); }";
      ] |> script;
      table [
        [ span ~cls:"time" @@ button "seek(0,10)" @@ text "00:10"; text "Session @ 2019-08-18" ];
        [ span ~cls:"time" @@ button "seek(0,35)" @@ text "00:35"; a "/sounds.html#17a699b" @@ text "L3" ];
        [ span ~cls:"time" @@ button "seek(2,0)" @@ text "02:00"; a "/sounds.html#01e765f" @@ text "Sunday meditations 1" ];
        [ span ~cls:"time" @@ button "seek(5,20)" @@ text "05:20"; text "Session @ 2019-12-11" ];
        [ span ~cls:"time" @@ button "seek(7,21)" @@ text "07:21"; a "/sounds.html#5920850" @@ text "M44" ];
        [ span ~cls:"time" @@ button "seek(11,47)" @@ text "11:47"; a "/sounds.html#ec936b3" @@ text "Sunday Jam 2" ];
        [ span ~cls:"time" @@ button "seek(13,40)" @@ text "13:40"; a "/sounds.html#a46694f" @@ text "Syltextrakt (14 augusti 2019)" ];
        [ span ~cls:"time" @@ button "seek(22,1)" @@ text "22:01"; a "/sounds.html#f310aa7" @@ text "Negative space" ];
        [ span ~cls:"time" @@ button "seek(24,45)" @@ text "24:45"; a "/sounds.html#cbf4c4a" @@ text "Plague Ostinato" ];
        [ span ~cls:"time" @@ button "seek(31,30)" @@ text "31:30"; text "Session @ 2019-08-07" ];
        [ span ~cls:"time" @@ button "seek(35,16)" @@ text "35:16"; text "Session @ 2019-09-05" ];
      ]
    ]
  ]
] |> pagemaker (Title "Best of rootmos 2019")
    ~additional_css:[ Utils.load_file (Path.style "bor19.css") ]

module ContentType = struct
  let is_video ct = Str.string_match (Str.regexp "^video/") ct 0
  let is_image ct = Str.string_match (Str.regexp "^image/") ct 0
end

let gallery title ?(preamble=None) ?(only_subtitle=true) fn =
  let s (g0: Gallery_j.entry) (g1: Gallery_j.entry) =
    Lenient_iso8601.compare g1.last_modified g0.last_modified in
  let es = Utils.load_file fn |> Gallery_j.entries_of_string |> List.sort s in

  let m (e: Gallery_j.entry) =
    let poster = match e.thumbnail with
      Some t -> begin
        match t.base64 with
          Some b64 -> Some (sprintf "data:%s;base64,%s" t.content_type b64)
        | None -> Some t.url
      end
      | None -> None in
    if ContentType.is_video e.content_type then video ~id:(e.id) ~poster e.url
    else if ContentType.is_image e.content_type then
      img ~id:e.id ~embedd:false e.url
    else failwith "content type not supported" in

  let g (e: Gallery_j.entry) = div ~cls:(Some "entry") @@ seq [
    m e;
    div ~cls:(Some "share") @@ a (e.id ^ ".html") @@ svg ~cls:"button" "fa/svgs/solid/share-alt.svg";
    begin match e.title with
      Some t -> p ~cls:(Some "title") @@ text t
    | None -> noop
    end;
    match e.description with
      Some t -> p ~cls:(Some "description") @@ text t
    | None -> noop;
  ] in

  let index = List.append
    (Option.map (div ~cls:(Some "preamble")) preamble |> Option.to_list)
    (List.map g es)
    |> seq |> div ~cls:(Some "gallery")
    |> pagemaker title
      ~additional_css:[ Utils.load_file (Path.style "gallery.css") ] in

  let p (e: Gallery_j.entry) =
    let og_image =
      match e.thumbnail with
        Some t -> Some t.url
      | None -> if ContentType.is_image e.content_type then Some e.url else None in
    let og_video =
      if ContentType.is_video e.content_type
      then text @@ sprintf "<meta property=\"og:video\" content=\"%s\" />" e.url
      else noop in
    let title =
      match e.title with
        Some t -> Page.Title t
      | None -> title in
    let og_type =
      if ContentType.is_video e.content_type then "video.movie"
      else "webpage" (* TODO what's the proper type for an image? *) in
    seq [
      m e;
      match e.description with
        Some t -> p ~cls:(Some "description") @@ text t
      | None -> noop;
    ] |> div ~cls:(Some "entry") |> div ~cls:(Some "gallery")
      |> pagemaker title ~back:(Some "index.html") ~meta:[ og_video ]
      ~og_image:og_image ~og_type:og_type
      ~additional_css:[ Utils.load_file (Path.style "gallery.css") ] in

  [ ("index.html", index ) ] @ List.map (fun (e: Gallery_j.entry) -> (sprintf "%s.html" e.id), p e) es

let glenn = gallery (Page.Title "Glenn, Glenn, Glenn") (Path.meta "glenn.json")
let silly = gallery (Title "Silly things") (Path.meta "silly.json")
let clips = gallery (Subtitle "clips") (Path.meta "clips.json")

let project human_title p =
  let preamble =
    let path = Path.meta (sprintf "projects/%s/preamble.md" p) in
    match Utils.file_exists path with
      false -> None
    | true -> Some (md_snippet path) in
  let path = Path.meta (sprintf "projects/%s/gallery.json" p) in
  match Utils.file_exists path with
    true -> gallery (Title human_title) ~preamble path
  | false -> failwith "not implemented"

let () =
  let webroot = Env.require "WEBROOT" ^ "/" ^ Env.require "ENV" in
  let write_page path p = Utils.write_file (Filename.concat webroot path) (p ~path) in

  let posts = Path.posts () >>| (fun path ->
    let rel = "post/" ^ Filename.chop_suffix (Filename.basename path) ".md" ^ ".html" in
    let post = Post.from_file path in
    let page = pagemaker (Title post.title) (div ~cls:(Some "post") @@ text post.html) in
    write_page rel page;
    (rel, post)
  ) |> List.sort (fun (_, { Post.date = d }) (_, { date = d' }) -> String.compare d d') in

  let posts_snippet = seq [
    h2 @@ text "Posts";
    posts >>| (fun (rel, { title; date }) ->
      a rel @@ text @@ sprintf "%s (%s)" title date
    ) |> ul
  ] in

  write_page "index.html" (index posts_snippet);
  write_page "sounds.html" sounds_page;
  write_page "jam.html" sounds_jam_page;
  write_page "demo.html" demo_page;
  write_page "practice.html" practice_page;
  write_page "activity.html" activity_page;
  write_page "bor19/index.html" bor19;

  let write_gallery key =
    List.iter (fun (fn, p) -> write_page (sprintf "%s/%s" key fn) p) in
  write_gallery "glenn" glenn;
  write_gallery "silly" silly;
  write_gallery "clips" clips;
  write_gallery "stellar-drift" @@ project "Stellar Drift project page" "stellar-drift"

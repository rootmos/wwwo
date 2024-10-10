open Html
open Printf

let livejs_src = "http://livejs.com/live.js"
let chartjs_src = "https://cdnjs.cloudflare.com/ajax/libs/Chart.js/2.9.3/Chart.min.js"
let momentjs_src = "https://cdnjs.cloudflare.com/ajax/libs/moment.js/2.29.0/moment.min.js"

(* TODO reinit and update *)
let tracking_id = "UA-124878438-2"
let tracking = seq [
  js_src (sprintf "https://www.googletagmanager.com/gtag/js?id=%s" tracking_id);
  String.concat "" [
    "window.dataLayer = window.dataLayer || [];";
    "function gtag(){dataLayer.push(arguments);} gtag('js', new Date());";
    sprintf "gtag('config', '%s')" tracking_id;
  ] |> script
]

let base_url = Env.require "BASE_URL"
let static = (^) "https://rootmos-static.s3.eu-central-1.amazonaws.com/"
let avatar_url = static "rootmos.jpg"


let make
  ?(only_subtitle=false)
  ?(livejs=false)
  ?(chartjs=false)
  ?(additional_css=[])
  ?(back="/index.html")
  ?(meta=[])
  ?(og_type="website")
  ?(og_image=None)
  subtitle b path =
  let t = if only_subtitle then Option.get subtitle else "rootmos' " ^ Option.fold ~some:Fun.id ~none:"what-nots" subtitle in
  () |> html @@ seq [
  head @@ seq @@ List.concat [
    [
      title @@ t;
      if livejs then js_src livejs_src else tracking;
      seq @@ if chartjs then [js_src momentjs_src; js_src chartjs_src]
      else [];
      css @@ Utils.load_file (Path.style "style.css") :: additional_css;
      text "<meta charset=\"UTF-8\">";
      favicon (Path.image "favicon.png");
      text @@ sprintf "<meta property=\"og:title\" content=\"%s\" />" t;
      text @@ sprintf "<meta property=\"og:url\" content=\"%s/%s\" />" base_url path;
      text @@ sprintf "<meta property=\"og:type\" content=\"%s\" />" og_type;
      text @@ sprintf "<meta property=\"og:image\" content=\"%s\" />" @@
        Option.value og_image ~default:avatar_url
    ];
    meta;
  ];
  body @@ seq [
    h1 @@ seq [
      text @@ t;
      if Option.is_some subtitle then
        span ~cls:"subtitle" @@ a back @@ text "back" else noop
    ];
    div ~cls:(Some "content") @@ b;
    div ~cls:(Some "footer") @@ seq [
      let t = Unix.time () |> Unix.gmtime in
      let c = Sys.getenv_opt "BUILD_GIT_REF_ID" |> Option.map (fun r ->
        a "/version.html" @@ span @@ text (String.sub r 0 7)
      )
      in span ~cls:"copyleft" @@ seq @@ Option.to_list c @ [
        text @@ sprintf " %d &copy;" (1900 + t.tm_year)
      ]
    ]
  ]
]

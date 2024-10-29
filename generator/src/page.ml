open Html
open Printf

let livejs_src = "http://livejs.com/live.js"
let chartjs_src = "https://cdnjs.cloudflare.com/ajax/libs/Chart.js/2.9.3/Chart.min.js"
let momentjs_src = "https://cdnjs.cloudflare.com/ajax/libs/moment.js/2.29.0/moment.min.js"

let tracking_id = "G-S1L923YT6Z"

let tracking_snippet id = seq [
  js_src (sprintf "https://www.googletagmanager.com/gtag/js?id=%s" id);
  String.concat "" [
    "window.dataLayer = window.dataLayer || [];";
    "function gtag(){dataLayer.push(arguments);} gtag('js', new Date());";
    sprintf "gtag('config', '%s')" id;
  ] |> script
]

let static = (^) "https://rootmos-static.s3.eu-central-1.amazonaws.com/"
let avatar_url = static "rootmos.jpg"

type title =
  | Default
  | Title of string
  | Subtitle of string

let render_title = function
| Title t -> t
| Subtitle st -> "rootmos' " ^ st
| Default -> "rootmos' what-nots"

module Config = struct
  type t = {
    livejs: bool;
    tracking: string option;

    additional_css: string list;
    meta: unit Html.t list;

    chartjs: bool;

    og_type: string;
    og_image: string option;

    canonical_url: string option;
    back: string option;
  }

  let default = {
    livejs = false;
    tracking = None;

    additional_css = [];
    meta = [];

    chartjs = false;

    og_type = "website";
    og_image = None;

    canonical_url = None;
    back = None;
  }

  let from_env () =
    match Env.opt "ENV" with
    | Some "dev" -> { default with
      livejs = true;
      tracking = None;
    }
    | Some "prod" -> { default with
      livejs = false;
      tracking = Some tracking_id;
    }
    | _ -> default
end

let make (config: Config.t) title content =
  let title = render_title title in
  () |> html @@ seq [
  head @@ seq @@ List.concat [
    [
      Html.title title;
      if config.livejs then js_src livejs_src else noop;
      begin match config.tracking with
      | Some id -> tracking_snippet id
      | None -> noop
      end;
      if config.chartjs then seq [js_src momentjs_src; js_src chartjs_src] else noop;
      css @@ Utils.load_file (Path.style "style.css") :: config.additional_css;
      text "<meta charset=\"UTF-8\">";
      favicon (Path.image "favicon.png");
      text @@ sprintf "<meta property=\"og:title\" content=\"%s\" />" title;
      begin match config.canonical_url with
      | Some url -> text @@ sprintf "<meta property=\"og:url\" content=\"%s\" />" url
      | None -> noop
      end;
      text @@ sprintf "<meta property=\"og:type\" content=\"%s\" />" config.og_type;
      text @@ sprintf "<meta property=\"og:image\" content=\"%s\" />" @@
        Option.value config.og_image ~default:avatar_url;
    ];
    config.meta;
  ];
  body @@ seq [
    h1 @@ seq [
      text title;
      match config.back with
      | Some url -> span ~cls:"subtitle" (* TODO "navigation"? *) @@ a url @@ text "back"
      | None -> noop;
    ];
    div ~cls:(Some "content") @@ content;
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

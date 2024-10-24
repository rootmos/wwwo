open Common
open Html
open Printf

open Git_activity_t

let render_date d = Lenient_iso8601.rfc5322_sec d

let all_activity =
  let cs = Path.meta "git-activity.json" |>
    Utils.load_file |> Git_activity_j.commits_of_string in
  let s c0 c1 = Lenient_iso8601.compare c1.date c0.date in
  cs |> List.sort s

let total = List.length all_activity

let public_activity = List.filter (fun c -> c.repo.public) all_activity
let private_activity = total - List.length public_activity

let render_commit c = [
    div ~cls:(Some "date") @@ text @@ render_date c.date;
    div ~cls:(Some "repository") @@ a c.repo.url @@ text c.repo.name;
    div ~cls:(Some "message") @@ a c.url @@ text @@ html_escape_string c.title;
  ]

let page pagemaker = seq [
  h2 @@ seq [
    text "Git activity during last month";
    span ~cls:"subtitle" @@ text @@ sprintf "not showing %d actions in private or unlisted repositories" private_activity;
  ];
  public_activity >>| render_commit |> table
] |> div ~cls:(Some "activity")
  |> pagemaker (Page.Subtitle "activity")

let snippet () = let n = 15 in seq [
  h2 @@ text "Recent Git activity";
  public_activity |> take n >>| render_commit |> table;
  if total > n
    then div ~cls:(Some "more") @@ a "activity.html" @@ text (sprintf "%d activities during last month" total)
    else noop;
] |> div ~cls:(Some "activity")

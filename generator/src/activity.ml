open Common
open Html
open Printf

open Git_activity_t

let render_date d = Lenient_iso8601.rfc5322_sec d

let activity =
  let cs = Path.meta "git-activity.json" |>
    Utils.load_file |> Git_activity_j.commits_of_string in
  let s c0 c1 = Lenient_iso8601.compare c1.date c0.date in
  cs |> List.sort s |> List.filter (fun c -> c.repo.public)

let render_commit c = [
    div ~cls:(Some "date") @@ text @@ render_date c.date;
    div ~cls:(Some "repository") @@ a c.repo.url @@ text c.repo.name;
    div ~cls:(Some "message") @@ a c.url @@ text @@ html_escape_string c.title;
  ]

let page pagemaker =
  activity >>| render_commit |> table |> div ~cls:(Some "activity")
  |> pagemaker (Page.Subtitle "activity")

let snippet () = let n = 15 in seq [
  h2 @@ text "Activity";
  activity |> take n >>| render_commit |> table;
  if List.length activity > n
    then (div ~cls:(Some "more") @@ a "activity.html" @@ text (sprintf "... and %d more activities during last month" (List.length activity - n)))
    else noop;
] |> div ~cls:(Some "activity")

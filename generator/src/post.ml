open Common
open Html

type t = {
    title: string;
    date: string;
    html: string;
}

let from_file path =
  let lines = Utils.load_file path |> String.split_on_char '\n' in
  let hs = String.concat "\n" @@ take_while ((<>) "---")
    @@ List.tl @@ drop_while ((<>) "---") lines in
  let bs = String.concat "\n" @@ List.tl @@ drop_while ((<>) "---")
    @@ List.tl @@ drop_while ((<>) "---") lines in

  let props = match Yaml.of_string_exn hs with `O pp -> pp | _ -> failwith "expected object" in
  let prop p = match List.find_opt (fun (k, _) -> k = p) props with
  Some (_, `String s) -> Some s | Some(_) -> failwith (p ^ " wrong type") | None -> None in

  let md = Omd.of_string bs in
  let md = md |> Omd_representation.visit @@ function
    | Omd_representation.Img (alt, src, _) ->
        let src = Path.image src in
        Omd_representation.Raw (img ~alt:(Some alt) src ()) :: [] |> Option.some
    | Omd_representation.Text "{{< toc >}}" -> Omd.toc md |> Option.some
    | _ -> None in

  let today =
    let open CalendarLib in
    Printer.Date.sprint "%F" (Date.today ())

  in {
    html = Omd.to_html md;
    date = Option.value ~default:today @@ prop "date";
    title = Option.get @@ prop "title";
  }

open Common
open Html

type t = {
    title: string;
    date: string;
    html: string;
    additional_css: string list;
    listed: bool;
}

let from_file path =
  let lines = Utils.load_file path |> String.split_on_char '\n' in
  let hs = String.concat "\n" @@ take_while ((<>) "---")
    @@ List.tl @@ drop_while ((<>) "---") lines in
  let bs = String.concat "\n" @@ List.tl @@ drop_while ((<>) "---")
    @@ List.tl @@ drop_while ((<>) "---") lines in

  let props = match Yaml.of_string_exn hs with `O pp -> pp | _ -> failwith "expected object" in

  let value_to_string = function
  | `String s -> Some s
  | _ -> None in

  let expect_string p = function
  | `String s -> s
  | _ -> failwith (p ^ " unexpected non-string") in

  let expect_bool p = function
  | `Bool b -> b
  | _ -> failwith (p ^ " unexpected non-boolean") in

  let prop p = match List.find_opt (fun (k, _) -> k = p) props with
    Some (_, v) -> Some v
  | None -> None in

  let prop_string p = Option.map (expect_string p) @@ prop p in
  let prop_bool p = Option.map (expect_bool p) @@ prop p in

  let prop_list p = match List.find_opt (fun (k, _) -> k = p) props with
    Some (_, `A vs) -> Some (List.filter_map value_to_string vs)
  | _ -> None in

  let embed_images = Option.value ~default:true @@ prop_bool "embed_images" in

  let md = Omd.of_string bs in
  let md = md |> Omd_representation.visit @@ function
    | Omd_representation.Img (alt, src, _) ->
        let src = if embed_images then Path.image src else src in
        let lazy_loading = not embed_images in
        let i = img ~alt:(Some alt) ~embed:embed_images ~lazy_loading src () in
        Omd_representation.Raw i :: [] |> Option.some
    | Omd_representation.Text "{{< toc >}}" -> Omd.toc md |> Option.some
    | _ -> None in

  let today =
    let open CalendarLib in
    Printer.Date.sprint "%F" (Date.today ())

  in {
    html = Omd.to_html md;
    date = Option.value ~default:today @@ prop_string "date";
    title = Option.get @@ prop_string "title";
    additional_css = Option.value ~default:[] @@ prop_list "additional_css";
    listed = Option.value ~default:true @@ prop_bool "listed";
  }

let make pagemaker (config: Page.Config.t) post =
  let config' = { config with
    additional_css = List.append
      config.additional_css
      (List.map (fun fn -> Utils.load_file @@ Path.style fn) ("post.css"::post.additional_css));
  } in
  pagemaker config'
    (Page.Title post.title)
    (div ~cls:(Some "post") @@ text post.html)

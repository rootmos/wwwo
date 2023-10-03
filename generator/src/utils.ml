let load_file f =
  let ic = open_in f in
  let s = really_input_string ic (in_channel_length ic) in
  close_in ic; s

(* quick and dirty implementation of a lenient mkdir *)
let mkdir p =
  match Unix.stat p with
  | { st_kind = Unix.S_DIR } -> ()
  | _ -> failwith "path already exists"
  | exception Unix.Unix_error(Unix.ENOENT, _, _) ->
      let _ = Unix.umask 0o000 in Unix.mkdir p 0o775

let write_file filename s =
  mkdir (Filename.dirname filename);
  let oc = open_out filename in
  output_string oc s;
  close_out oc

let file_exists p =
  match Unix.stat p with
    _ -> true
  | exception Unix.Unix_error(Unix.ENOENT, _, _) -> false

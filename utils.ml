let load_file f =
  let ic = open_in f in
  let s = really_input_string ic (in_channel_length ic) in
  close_in ic; s

let write_file filename s =
  let oc = open_out filename in
  output_string oc s;
  close_out oc

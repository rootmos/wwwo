open Post
open Html

let () =
  let usage_msg = Filename.basename @@ Sys.argv.(0) in
  let source = ref "-" in
  let output = ref "-" in
  let content = ref "." in
  let speclist = [
    ( "-src", Arg.Set_string source, "source file" );
    ( "-output", Arg.Set_string output, "output file" );
    ( "-content", Arg.Set_string content, "content directory" );
  ] in
  Arg.parse speclist (fun _ -> raise @@ Arg.Bad "unexpected argument") usage_msg;

  Path.set_content_root !content;

  let post = Post.from_file !source in
  let str = Post.make Page.make (Page.Config.from_env ()) post in
  match !output with
  | "-" -> print_string str
  | path -> Utils.write_file path str

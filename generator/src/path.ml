let content_root = ref @@ Env.get2 "CONTENT" "./content"
let set_content_root = (:=) content_root

let posts () = Sys.readdir (Filename.concat !content_root "post") |> Array.to_list
let post file = Filename.concat (Filename.concat !content_root "post") file
let snippet file = Filename.concat (Filename.concat !content_root "snippet") file
let image file = Filename.concat (Filename.concat !content_root "image") file
let style file = Filename.concat (Filename.concat !content_root "css") file
let js file = Filename.concat (Filename.concat !content_root "js") file


let meta_root = ref @@ Env.get2 "META" "./meta"
let set_meta_root = (:=) meta_root

let meta file= Filename.concat !meta_root file

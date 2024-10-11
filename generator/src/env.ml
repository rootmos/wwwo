let prefix = "WWWO_"

let get var = Sys.getenv @@ prefix ^ var
let opt var = Sys.getenv_opt @@ prefix ^ var
let get2 var default = Option.value ~default:default @@ opt var

let require var =
    let k = prefix ^ var in
    match Sys.getenv_opt k with
      Some v -> v
    | None -> failwith @@ "set " ^ k

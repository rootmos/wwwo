let prefix = "WWWO_"

let get var = Sys.getenv @@ prefix ^ var
let opt var = Sys.getenv_opt @@ prefix ^ var
let get2 var default = Option.value ~default:default @@ opt var

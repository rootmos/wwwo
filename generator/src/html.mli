type 'a t = 'a -> string

val html : 'a t -> 'a t
val body : 'a t -> 'a t
val head : 'a t -> 'a t

val noop : 'a t
val seq : ('a -> string) list -> 'a t

val title : string -> 'a t
val favicon : ?embedd:bool -> string -> 'a -> string

val text : string -> 'a t
val html_escape_string : String.t -> string

val tag :
  ?id:string option ->
  ?cls:string option -> ?style:string option -> string -> 'a t -> 'a t

val p :
  ?cls:string option ->
  ?id:string option -> ?style:string option -> 'a t -> 'a t

val h1 : 'a t -> 'a t
val h2 : 'a t -> 'a t

val ul : ?cls:string option -> 'a t list -> 'a t
val ul' : ?cls:string option -> 'a t list -> 'a t
val ol : 'a t list -> 'a -> string
val li : ?cls:string option -> 'a t -> 'a t

val table : ?widths:int list option -> 'a t list list -> 'a t

val div :
  ?id:string option ->
  ?cls:string option -> ?style:string option -> 'a t -> 'a t
val span : ?cls:string -> ('a -> string) -> 'a -> string

val audio : ?id:string -> Camomile.UTF8.t -> 'a t
val video : ?id:string -> ?poster:string option -> Camomile.UTF8.t -> 'a t
val canvas : string -> int -> int -> 'a t

val a : Camomile.UTF8.t -> ('a -> string) -> 'a -> string
val button : string -> ('a -> string) -> 'a -> string

val img :
  ?id:string ->
  ?embed:bool ->
  ?lazy_loading:bool ->
  ?cls:string option ->
  ?alt:string option -> ?onclick:string option -> string -> 'a -> string
val img_b64 :
  ?cls:string option ->
  ?alt:string option -> string -> string -> 'a -> string
val svg : ?cls:string -> string -> 'a t

val js_src : string -> 'a -> string
val minimize_css : string -> string
val css : string list -> 'a t
val minimize_js : string -> string
val script : string -> 'a t

# wwwo
[![Build, upload and publish](https://github.com/rootmos/wwwo/actions/workflows/publish.yaml/badge.svg)](https://github.com/rootmos/wwwo/actions/workflows/publish.yaml)

This is my semi-static pseudo-dynamic website generator for [my homepage](https://rootmos.io):
1. The content is gathered by a set of [tasks](tasks) implemented in Python, for example:
   - scrapes a couple of S3 buckets
   - GitHub and [sourcehut](https://sr.ht/) (using a [small wrapper](tasks/src/tasks/sourcehut.py) for it's [GraphQL API](https://man.sr.ht/git.sr.ht/graphql.md))
   - Twitch
2. which is then rendered into HTML using a custom continuation-passing style generator written in OCaml,
3. a [Docker image to rule them all](Dockerfile) is built combining the necessary Python and OCaml build environments,
   - note the poor man's package manager-like wrappers [around ocamlfind](bin/buildml)
3. this image is executed periodically in an AWS Lambda function that publish the result to S3 and is
4. hosted by an OpenBSD server created using my [own image builder](https://github.com/rootmos/openbsd).

The o in wwwo is simultaneously a reference to OCaml but primarily the goal naming style of [miniKanren](http://minikanren.org/).

## The Html module
A small [continuation-passing style](https://en.wikipedia.org/wiki/Continuation-passing_style) HTML generator.

The following small example:
```ocaml
open Html

let page = () |> html @@ seq [
    head @@ seq [
        title "Hello";
    ];
    body @@ seq [
        h1 @@ text "Hello";
    ];
]

let () = Utils.write_file "hello.html" page
```
generates the following HTML (after pretty-printing using [tidy](http://www.html-tidy.org/)):
```html
<!DOCTYPE html>
<html>
  <head>
    <title>
      Hello
    </title>
  </head>
  <body>
    <h1>
      Hello
    </h1>
  </body>
</html>
```

The [module](generator/src/html.ml) has the following interface:
```ocaml
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
val ol : 'a t list -> 'a -> string

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
```

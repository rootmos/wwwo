# wwwo
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

## The Html module
A small [continuation-passing style](https://en.wikipedia.org/wiki/Continuation-passing_style) HTML generator.

The following small example:
```ocaml
@include "hello.ml"
```
generates the following HTML (after pretty-printing using [tidy](http://www.html-tidy.org/)):
```html
@include "hello.pretty.html"
```

The [module](generator/src/html.ml) has the following interface:
```ocaml
@include "html.mli"
```

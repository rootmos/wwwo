# wwwo

## The Html module

### Example
The following [small example](generator/src/hello.ml):
```ocaml
@include "hello.ml"
```
generates the following HTML (after pretty-printing using [tidy](http://www.html-tidy.org/)):
```html
@include "hello.pretty.html"
```

### Interface
```ocaml
@include "html.mli"
```

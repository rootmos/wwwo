---
layout: default
title:  "A small nanopass example"
date:   2017-05-30
aliases: [/main/2017/05/30/a-small-nanopass-example.html]
categories: main
---

{{< toc >}}

The [nanopass framework](http://nanopass.org) is a scheme framework
for writing compilers using tiny passes transforming the AST.
The framework helps you immensely by generating transformers for you,
in particular it handles recursively calling the appropriate transformers
for the different kinds of terms in your AST.

Its implementations support [Chez scheme](https://github.com/nanopass/nanopass-framework-scheme) and
[Racket](https://github.com/nanopass/nanopass-framework-racket).
The Racket implementation also has some accompanying [documentation](http://docs.racket-lang.org/nanopass/index.html).

However I found more answers to my hands-on questions by looking at the
[scheme-to-c](https://github.com/akeep/scheme-to-c) compiler source.
Although it's very well commented, it's quite a difficult read when not used
to the framework.

So in order to showcase some of the framework's features and perhaps
help new users, I decided to write down a small example of
transforming a silly arithmetic language into [Church encoded](https://en.wikipedia.org/wiki/Church_encoding)
lambda calculus, which is trivial to then transform back into scheme.

For this example I've used [Chez scheme](http://www.scheme.com/) for no other
reason than that I [saw Friedman and Byrd use it](https://www.infoq.com/presentations/miniKanren)
when showing of [miniKanren](http://minikanren.org/).

# Demo time!
[The example code](https://github.com/rootmos/silly-church) has a REPL, where
we can evaluate our highly advanced scientifically important arithmetic calculations:

```scheme
silly-church> (+ (- 3 1) (* 2 4))
10
```

For a moment one might have the desire to know the resulting Church encoding,
that urge can be satisfied as well:

```scheme
> (encode '(+ (- 3 1) (* 2 4)))
(((lambda (m)
    (lambda (n) (lambda (f) (lambda (x) ((m f) ((n f) x))))))
   ((((lambda (pred) (lambda (m) (lambda (n) ((n pred) m))))
       (lambda (n)
         (lambda (f)
           (lambda (x)
             (((n (lambda (g) (lambda (h) (h (g f))))) (lambda (u) x))
               (lambda (u) u))))))
      (lambda (f) (lambda (x) (f (f (f x))))))
     (lambda (f) (lambda (x) (f x)))))
  (((lambda (m) (lambda (n) (lambda (f) (m (n f)))))
     (lambda (f) (lambda (x) (f (f x)))))
    (lambda (f) (lambda (x) (f (f (f (f x))))))))
```
but without further stalling for time...

# Show me the code!
The code is kept [here](https://github.com/rootmos/silly-church) and
as an overview, the small "compiler" goes through these passes:

* `ast-to-Lsrc`
* `encode-numbers`
* `curry-operators`
* `encode-operators`
* `output-scheme`

The passes are primarily designed to showcase different feature of the nanopass
framework, or secondarily perhaps to keep your [black box hot](https://www.youtube.com/watch?v=iSmkqocn0oQ&feature=youtu.be&t=3m23s).

## The language `Lsrc` and the pass `ast-to-Lsrc`

```scheme
(define-language Lsrc
  (terminals
    (number (n))
    (operator (op)))
  (Expr (e)
    n
    (op e0 e1)))
```

The terminals all need to have corresponding predicates, and since `number?`
is already defined we only need to define:
```scheme
(define (operator? x) (memq x '(+ - *)))
```

The first and last pass of a compiler written in the nanopass framework are quite
different from the passes in between. Or to be precise, any pass to or from
anything other than a language defined in the framework's syntax.

The first pass has to transform a regular scheme list, represented
in the nanopass framework as the `*` language, into our `Lsrc` language.
Here is how that is done:
```scheme
(define-pass ast-to-Lsrc : * (ast) -> Lsrc ()
  (parse : * (e) -> Expr ()
    (cond
      [(number? e) e]
      [(and (list? e) (= 3 (length e)))
       (let ([op (car e)] [e0 (parse (cadr e))] [e1 (parse (caddr e))])
       `(,op ,e0 ,e1))]))
  (parse ast))
```
Noteworthy things are:

* The defined pass `ast-to-Lsrc` transforms the untyped language `*` into the
  language `Lsrc`.
* `parse` defines a *transformer* from anything `*` (i.e. a list) into the `Expr`:s of
  the target language `Lsrc`. The first pair of parenthesis name the arguments for the transformer
  and the last pair tells you that it will not return any additional
  [values](http://www.scheme.com/tspl4/control.html#./control:h8).
* Because the input language is `*` the framework can't automatically figure out
  how to kick off the transformation, hence the need of the last explicit call
  to our transformer `(parse ast)`. The `ast` term in the call is given its name when
  defining the type of the pass in the first line. (Note that, just like transformers,
  passes can receive multiple arguments as well as return multiple values.)


## The language `L1` and the pass `encode-numbers`
Here we encode the numbers into lambdas and applications, so the
next language reflects exactly that:
```scheme
(define-language L1
  (extends Lsrc)
  (terminals
    (- (number (n)))
    (+ (variable (v))))
  (Expr (e)
    (- n)
    (+ v)
    (+ (lambda (v) e))
    (+ (apply e0 e1))))
```

To look at the full definition of a language do:
```scheme
> (language->s-expression L1)
(define-language L1
  (entry Expr)
  (terminals (variable (v)) (operator (op)))
  (Expr (e) (apply e0 e1) (lambda (v) e) v (op e0 e1)))
```

The `encode-numbers` pass encodes numbers using a small recursive function:
```scheme
(define-pass encode-numbers : Lsrc (ast) -> L1 ()
  (Expr : Expr (e) -> Expr ()
    [,n (letrec ([go (lambda (n) (if (= n 0) `x `(apply f ,[go (- n 1)])))])
        `(lambda (f) (lambda (x) ,[go n])))]))
```

Note that since the `(op e0 e1)` expression is not affected by this transformation
it's not explicitly stated in the transformer. Here's the automagic, the
nanopass framework generates cases for these with the
appropriate recursive calls. That is, even deeply nested numbers get
encoded by this pass without us having to bother to take care of the recursion
over the AST.


## The language `L2` and the pass `curry-operators`
Since our target lambda calculus only support lambda abstractions
with arity one we need to expand the dyadic `(op e0 e1)` into two
applications.

The `L2` language reflects this change:
```scheme
(define-language L2
  (extends L1)
  (Expr (e)
    (+ op)
    (- (op e0 e1))))
```
Note that the `op` terminal became an `Expr` on its own, since it
will take the place of one the `e`:s in `(apply e0 e1)`.

The `curry-operators` pass does the actual work:
```scheme
(define-pass curry-operators : L1 (ast) -> L2 ()
  (Expr : Expr (e) -> Expr ()
    [(,op ,e0 ,e1)
     `(apply (apply ,op ,[Expr e0]) ,[Expr e1])]))
```
Note that we need to explicitly invoke our `Expr`-transformer recursively
to transform the two sub-expressions `e0` and `e1`. That is, the framework
does not automagically transform the input expression `e0` of type `L1 Expr`
into `L2 Expr`, but that's exactly the type of the defined `Expr` transformer.


## The language `L3` and the pass `encode-operators`
Now we're quite ready to encode the operators:
```
(define-language L3
  (extends L2)
  (terminals
    (- (operator (op))))
  (Expr (e)
    (- op)))
```
and what we're left with is just:
```scheme
> (language->s-expression L3)
(define-language L3
  (entry Expr)
  (terminals (variable (v)))
  (Expr (e) (apply e0 e1) (lambda (v) e) v))
```

The actual pass transforms the operators following
[this table](https://en.wikipedia.org/wiki/Church_encoding#Table_of_functions_on_Church_numerals).
Since this in itself is not a nanopass related exercise, I've taken
the opportunity to showcase the `with-output-language` syntax, which interprets
quasiquoted lists as the chosen output language's non-terminal (here the `Expr`):
```scheme
(define-pass encode-operators : L2 (ast) -> L3 ()
  (definitions
    (with-output-language (L3 Expr)
      (define plus
        `(lambda (m) (lambda (n) (lambda (f) (lambda (x)
           (apply (apply m f) (apply (apply n f) x)))))))
      (define pred
        `(lambda (n) (lambda (f) (lambda (x)
           (apply
             (apply
               (apply n (lambda (g) (lambda (h) (apply h (apply g f)))))
               (lambda (u) x))
             (lambda (u) u))))))
      (define minus
        `(apply
           (lambda (pred)
             (lambda (m) (lambda (n) (apply (apply n pred) m))))
           ,pred))
      (define multiply
        `(lambda (m) (lambda (n) (lambda (f)
           (apply m (apply n f))))))))
  (Expr : Expr (e) -> Expr ()
    [,op
     (case op
       [+ plus]
       [- minus]
       [* multiply]
       [else (error 'encode-operators "unsupported operator" op)])]))
```

## The pass `output-scheme`
The final pass simply transforms the `L3` language into scheme,
quite effortlessly:
```scheme
(define-pass output-scheme : L3 (ast) -> * ()
  (Expr : Expr (e) -> * ()
    [,v v]
    [(apply ,e0 ,e1) `(,[Expr e0] ,[Expr e1])]
    [(lambda (,v) ,e) `(lambda (,v) ,[Expr e])]))
```
and this pass completes the journey from `*` to `*`! Happy passing!

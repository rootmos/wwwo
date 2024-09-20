---
layout: default
title: "Implementing a K-like language targeting Malfunction"
date: 2017-06-09
aliases: [main/2017/06/09/implementing-a-k-like-language-targeting-malfunction.html]
categories: main
---
{{< toc >}}

This post is all about my silly-k project:
a small experimental [K-like](https://web.archive.org/web/20230411111549/https://kparc.com/k.txt), [APL inspired](http://www.eecg.toronto.edu/~jzhu/csc326/readings/iverson.pdf), [nanopass compiled](https://github.com/nanopass/nanopass-framework-scheme),
language targeting [Malfunction](https://github.com/stedolan/malfunction).
The [code lives on GitHub](https://github.com/rootmos/silly-k) and the [tests are run by Travis](https://travis-ci.org/rootmos/silly-k).

The a posteriori motivation for the language is summarized into these two points:

* performance of recursive algorithms should be similar to the ML-family
* have syntax similar to K but be compiled to a native runtime making no
  use of type-checks

**Disclaimer** The *silly* prefix is used to indicate that the language is a fun experiment,
and to indicate, by way of contrast, the amazing nature of APL and K.

# Background
I wanted to implement a language with:

* a compiler in the nanopass style
* simply typed lambda calculus
* [Malfunction](https://github.com/stedolan/malfunction)
* type-inference (in particular I wanted to use the Hindley-Milner style type reconstruction I read about in [TaPL](https://www.cis.upenn.edu/~bcpierce/tapl/) §22.4)
* [APL](http://www.eecg.toronto.edu/~jzhu/csc326/readings/iverson.pdf)/[J](https://code.jsoftware.com/wiki/NuVoc)/[K](https://web.archive.org/web/20230411111549/https://kparc.com/k.txt) inspired syntax

The harmony between these chosen goals was not taken into account a priori,
that was part of the adventure!

Malfunction is what you get when you cut the OCaml's compiler in half
and put a simple lambda calculus-like syntax in front.
You thus get the optimization, code-generation and all
of OCaml's ecosystem with an easy to target language for your compiler.

Malfunction's input language is based on s-expressions, so I thought:
why not write the compiler in Scheme using the [nanopass-framework](https://github.com/nanopass/nanopass-framework-scheme).

Before writing the compiler I had just read the book [The Reasoned Schemer](https://mitpress.mit.edu/books/reasoned-schemer) about [miniKanren](http://minikanren.org/)
so Scheme was the language I was learning at the time,
I had barely used it before reading that book.

During spring this year I got quite fed up with coding in the industry's
*JSON in, JSON out* where all code seems intellectually [useless](https://github.com/rootmos/ppx_useless).

The only remedy that worked was APL.
Introduced to me by my friend and colleague [inrick](https://github.com/inrick) (thank you for suffering through all the *silly*-ness!).
He also showed me K and J, preferring K himself.

For reference, here are some implementations of the mentioned languages:

* [Dyalog APL](https://www.dyalog.com/), which is [very well documented](https://www.dyalog.com/documentation_150.htm#CORE)
* [J](https://en.wikipedia.org/wiki/J_(programming_language)), a related language created by Iverson, [here's its vocabulary](http://code.jsoftware.com/wiki/NuVoc)
* [The official K](https://kx.com/download/), closed source (but it's the real thing!)
* [Kona](https://github.com/kevinlawler/kona), open source with a [well stocked wiki](https://github.com/kevinlawler/kona/wiki)
* [oK](https://github.com/JohnEarnest/ok), open source, can be run in the browser

The code density is absolutely amazing, finally I can read the code without
hurting my wrists, straining my memory or being forced to use an IDE.
On this note I highly recommend checking out [this talk](https://youtu.be/gcUWTa16Jc0) by the author of [co-dfns](http://arcfide.github.io/Co-dfns/),
and in particular the points he makes about
[tools and complexity](https://youtu.be/gcUWTa16Jc0?t=14m07s) and the benefits of the
[high semantic density (of APL)](https://youtu.be/gcUWTa16Jc0?t=37m11s).

I was hooked immediately, and its [legacy can't be disputed](https://www.youtube.com/watch?v=_DTpQ4Kk2wA)
nor [its power](https://www.youtube.com/watch?v=a9xAKttWgP4).

I started writing [my solutions](https://github.com/rootmos/apl-hack) to [Project Euler](https://projecteuler.net/)
using [Dyalog APL](https://www.dyalog.com/),
and with just about 6 lines of code per solution it was an enormous contrast
to my everyday job writing Scala, which, though terser than [Java](http://docs.spring.io/spring/docs/2.5.x/javadoc-api/org/springframework/aop/config/SimpleBeanFactoryAwareAspectInstanceFactory.html), you're
strained to write anything other than Hello World using 6 lines of code.
The fun part was that it wasn't even difficult to solve the problems, often
the solution could be read verbatim without jumping around in the source code,
and the speed with which one can translate an idea into code is amazing.

Clearly Iverson was on to something.

Enter the [K language](https://web.archive.org/web/20230411111549/https://kparc.com/k.txt), which is a spiritual successor to APL,
featuring (among many many things) heavily overloaded operators.
[My idea was to use](https://en.wikipedia.org/wiki/Shoehorn) the type-inference to resolve the overloading,
so that the runtime code does not have to do any type-checks.

However, my thinking processes are still recursive and haven't yet fully adapted
to a vector based mind-set.

# Case-study: Naive Fibonacci
I was surprised the naive Fibonacci algorithm had such atrocious performance in K:
```k
fib:{$[x<2;1;_f[x-1]+_f[x-2]]}
```
Of course it's not a good algorithm to start with, nor very suitable to evaluate
in an array focused language.
But when I went back to [Haskell](https://gist.github.com/398b1bfac72d1db21e129a4f9f328925)
or [OCaml](https://gist.github.com/a6ffe3d07f766dcaa1318a875d9d1c6f)
or [C](https://gist.github.com/77c52aa3c1cac2eb0bd077ee5d08a8ad),
they all allowed me to be naive for a while.
On my laptop it took about 8 minutes for `fib 44` to terminate in K,
compared to around 4-5 seconds in the other languages I tried.

At this point I thought, what might be going on here?
I then tried the same code in [Python](https://gist.github.com/feb5917c0991b54d24290bb16edd7739),
which terminated after about 4 minutes.
One hypothesis is that it's the interpretative nature of K and Python
that make them so slow.
That seems to be part of the explanation for Python at least, with [pypy](https://pypy.org/)
the time was 22 seconds.
I also tried [Chez scheme](https://gist.github.com/990c3455b0a63181cf877d547186e705),
which had just slightly worse performance (clocking in at 6 seconds).
I'm thinking runtime type-checks does not impact performance in that magnitude.

Question then: what would be the performance of K if it were compiled?
As far as I know, there's no compiling variant of K, and so that serves
as part of the motivation for implementing silly-k.

# The silly-k language
These are some of the intended features of the language:

* compiled (via Malfunction)
* interpreted (via Scheme backend)
* anonymous functions in a [dfns style](https://www.dyalog.com/uploads/documents/Papers/dfns.pdf)
  with `a` and `w` as the ASCII counterparts for `α` and `ω`
* overloaded operators that are resolved using type-inference during compilation
* coercion of booleans to integers, meaning that you can for instance sum a vector of booleans
* let-bindings with scoping rules similar to K's

The basic idea of translating the APL or K-like syntax is to
transform the expression `l{a+w}r` into an intermediate form:
```
(apply (apply (lambda (w) (lambda (a) a+w)) r) l)
```
Note here that the right-hand argument is evaluated before the left-hand element,
which indicates that expressions should both be read and evaluated from right to left.

The source code is parsed using a parser generated by the [lalr-scm](https://github.com/schemeway/lalr-scm)
parser generator. This parser generator was used primarily because
at the time I was not interested to write a parser myself, the focus was on the compiler internals.

This intermediate language is transformed by the compiler
(through 17 intermediate languages and 22 passes) into an underlying language with,
for instance, only monomorphic, scalar and dyadic
arithmetic operators, in contrast to the source language where `+` can be applied
to both scalars and vectors on both sides.

The underlying language of the compiler is then translated (quite trivially at this point)
to either Scheme, for the REPL, or into Malfunction for compilation.

## Overloading
Overloaded types of a term is handled by providing an ordered list of alternative
sets of constraints for the unification algorithms to try.

Consider the `+` operator, it can be given 4 possible types:

* `int -> int -> int` (from the expression: `1+2`, i.e. scalar addition)
* `(vector int) -> int -> (vector int)` (from the expression: `1+2 3 4`, i.e. distributed partially applied addition, map)
* `int -> (vector int) -> (vector int)` (from the expression: `1 2 3+4`, i.e. distributed partially applied addition, map)
* `(vector int) -> (vector int) -> (vector int)` (from the expression: `1 2+3 4`, i.e. point-wise addition, zip)

Here I'm using the conventional arrow-style of encoding functions types.
Internally the type `a -> b -> c` is represented simply as
```
(lambda a (lambda b c))
```

Meaning that when the unification algorithm has given `+` the type `(vector int) -> int -> (vector int)`, we can replace
that `+` with the following expression based on the primitive scalar operator `+` instead:
```
(lambda (ys) (lambda (x)
  (apply
    (apply
      (primfun map)
      (lambda (y)
        (apply (apply (primfun +) y) x)))
    ys)))
```
Here I've omitted the type annotations included in the actual intermediate language,
the primitive function `map` has the expected type polymorphic type `(a -> b) -> (vector a) -> (vector b)`.

## Coercion
Using the overloading mechanism described above, it was quite easy implement
coercion of booleans into integers.
In particular the following expression should type and evaluate correctly:
```
+/0=1 0 2 0 3
```
to `2`.
Here a coercion is necessary since `0=1 0 2 0 3` has type `(vector bool)`
and we want to count the `true` values of that vector.

With knowledge of the OCaml runtime code one might interject:
"Why not treat them the same, i.e. just a word?"
Well, at least we expect only boolean values in conditionals, and
in the OCaml code we can throw away the actual coercion when generating
code.
Note that extending conditionals to allow integers and treat any non-zero
value as `true` would after code generation be exactly the same as having
explicit coercion.
Hence I preferred to have more type information during compilation, not over-complicate
the conditional expression, and chiefly confirm the flexibility of the
nanopass compiler by adding explicit coercion by reusing the overloading mechanism,
which was already introduced.

Adding coercion was just adding another pass that introduced *coercion-points*
surrounding each expression in an `apply` node.
Assume that the wrapped expression has type `a` and that the coercion-point is given
the fresh type `b`, then these constraints are tried in order:

1. `b = a`
2. `a = bool` and `b = int`
3. `a = (vector bool)` and `b = (vector int)`

After unification using these types, the coercion-points that were given the same type (first case above)
are thrown away, the others are translated into corresponding primitive functions,
taking the appropriate action when generating Malfuction-code (just identity function) or
Scheme.

### At-operator
Having coercion in the language already simplified implementation of
the At operator. As an example, assume `l` is a list with values `1 2 3`,
then `l@1` should evaluate to `2`.
That is, I'm following K and have `⎕IO←0` (i.e. the *index origin* from APL for the uninitiated).

The `@` symbol is only used in the parser to generate
a monadic apply of the left-hand side to the right-hand side.
This means that when we try to type `l` we would want to give it the type
of `int -> a` assuming that `l` has type `(vector a)`.

That can be expressed using the coercion mechanism. Assume that the wrapped expression
has type `a` and the coercion point has type `b`, then these constraints are tried:
`a = (vector c)` and `b = int -> c`, where `c` is a fresh type-variable.

After unification these coercions are easily detectable by their given types
and translating them into appropriate primitive functions is easy.

## Let-bindings using a "let-spine"
Consider the expression `x+x:7`, which is interpreted as:

1. evaluate 7
2. bind the result of the evaluation the name `x`
3. apply `+` to `x` (I'll denote the partial application as `+x`)
4. apply `+x` to `x`

This expression is translated by silly-k into this AST:
```
(apply (apply plus (let (x) 7)) x)
```
and represented graphically:

![x+x:7 without let-spine](bind01.png)

However, the scoping rules of the lambda calculus do not accept this.
In lambda calculus with let-bindings this would read:
```
(apply (apply plus (let (x 7) x)) x)
```
The lexically scoped binding of `x` does nothing to help
us interpret the outer `x`.

What we want is closer to dynamic scoping: once the `x` is bound the binding
is in scope for any subsequent evaluation (unless it's rebound of course).

To stay within the realms of lambda calculus and its lexical scope, silly-k
binds a name to every evaluated value, called its *spine-value*, so when the `x`
is encountered it's substituted for the corresponding spine-value.

The AST gets rebalanced into a right-biased tree, from which I took its name,
the *let-spine*:
![x+x:7 with let-spine](bind01-spine.png)

Note that the apply nodes have only spine-values as leafs, indicating that both
have been evaluated before and have been given bindings for eventual referrals
late in the expression.

This is not a particularly beautiful nor performant (compile time and optimization time is severely impacted),
but it's a simple solution that allows a more direct translation into simply typed lambda calculus.

Interestingly, the OCaml compiler manages to optimize away most
of the generated let:s (i.e. the lambdas and apply:s).

If reference cells were added to Malfunction this approach would not be necessary.
However, for me it's soothing to know that it's possible to translate at least some
of the scoping of K to simple lambda calculus.

Of course one can easily achieve a reference cell or like we wanted here a mutable dictionary
by referring to linked in OCaml code using the `global` syntax in Malfunction.
I felt this is not in line with the goal of silly-k: translate K into a somewhat
pure lambda calculus.

# silly-k by examples
These examples are taken directly from the [tests](https://github.com/rootmos/silly-k/blob/master/tests.scm).

### Numbers and comparisons

<table>
<tr><th>Code</th><th>Result</th></tr>
<tr><td><code>]7</code></td><td><code>7</code></td></tr>
<tr><td><code>]1 2 3</code></td><td><code>1 2 3</code></td></tr>
<tr><td><code>]1=2</code></td><td><code>0</code></td></tr>
<tr><td><code>]2=2</code></td><td><code>1</code></td></tr>
<tr><td><code>]1 2 3=3</code></td><td><code>0 0 1</code></td></tr>
<tr><td><code>]1=1 2 3</code></td><td><code>1 0 0</code></td></tr>
<tr><td><code>]~1=2</code></td><td><code>1</code></td></tr>
<tr><td><code>]~2=2</code></td><td><code>0</code></td></tr>
<tr><td><code>]2<3</code></td><td><code>1</code></td></tr>
<tr><td><code>]2<2</code></td><td><code>0</code></td></tr>
<tr><td><code>]3<2</code></td><td><code>0</code></td></tr>
<tr><td><code>]1<1 2 3</code></td><td><code>0 1 1</code></td></tr>
<tr><td><code>]1 2 3>2</code></td><td><code>0 0 1</code></td></tr>
</table>

### Arithmetic operators

<table>
<tr><th>Code</th><th>Result</th></tr>
<tr><td><code>]1+2 3</code></td><td><code>3 4</code></td></tr>
<tr><td><code>]1 2+3 4</code></td><td><code>4 6</code></td></tr>
<tr><td><code>]1 2+3</code></td><td><code>4 5</code></td></tr>
<tr><td><code>]2-3</code></td><td><code>-1</code></td></tr>
<tr><td><code>]1-(-2)</code></td><td><code>3</code></td></tr>
<tr><td><code>]1 2-3 4</code></td><td><code>-2 -2</code></td></tr>
<tr><td><code>]-7</code></td><td><code>-7</code></td></tr>
<tr><td><code>]-(-2)</code></td><td><code>2</code></td></tr>
<tr><td><code>]1-2 3</code></td><td><code>-1 -2</code></td></tr>
<tr><td><code>]1 2-3</code></td><td><code>-2 -1</code></td></tr>
<tr><td><code>]2*3</code></td><td><code>6</code></td></tr>
<tr><td><code>]1 2*3</code></td><td><code>3 6</code></td></tr>
<tr><td><code>]4*2 3</code></td><td><code>8 12</code></td></tr>
<tr><td><code>]1 2*3 4</code></td><td><code>3 8</code></td></tr>
</table>

### Array operators

<table>
<tr><th>Code</th><th>Result</th></tr>
<tr><td><code>]!4</code></td><td><code>0 1 2 3</code></td></tr>
<tr><td><code>]*1 2 3</code></td><td><code>1</code></td></tr>
<tr><td><code>]#1 2 3 4</code></td><td><code>4</code></td></tr>
<tr><td><code>]4#1 2</code></td><td><code>1 2 1 2</code></td></tr>
<tr><td><code>]3#1</code></td><td><code>1 1 1</code></td></tr>
<tr><td><code>]1 2 3@1</code></td><td><code>2</code></td></tr>
<tr><td><code>]1 2 3@0 2</code></td><td><code>1 3</code></td></tr>
<tr><td><code>]&1 2 3</code></td><td><code>0 1 1 2 2 2</code></td></tr>
<tr><td><code>]7 8@&2 3</code></td><td><code>7 7 8 8 8</code></td></tr>
</table>

### Each and reduce adverbs

<table>
<tr><th>Code</th><th>Result</th></tr>
<tr><td><code>]{w+1}'1 2 3</code></td><td><code>2 3 4</code></td></tr>
<tr><td><code>]{1-w}'3 4 5</code></td><td><code>-2 -3 -4</code></td></tr>
<tr><td><code>]2+'3 4 5</code></td><td><code>5 6 7</code></td></tr>
<tr><td><code>]2-'3 4 5</code></td><td><code>-1 -2 -3</code></td></tr>
<tr><td><code>]2{a+w}'3 4 5</code></td><td><code>5 6 7</code></td></tr>
<tr><td><code>]2{w-a}'3 4 5</code></td><td><code>1 2 3</code></td></tr>
<tr><td><code>]{w@1}'{+w}'1 2 3</code></td><td><code>2 3 4</code></td></tr>
<tr><td><code>]{w@1}'{-w}'1 2 3</code></td><td><code>0 -1 -2</code></td></tr>
<tr><td><code>]+/1 2 3</code></td><td><code>6</code></td></tr>
<tr><td><code>]-/1 2 3</code></td><td><code>2</code></td></tr>
<tr><td><code>]{w-a}/1 2 3</code></td><td><code>0</code></td></tr>
<tr><td><code>]+/2<!5</code></td><td><code>2</code></td></tr>
<tr><td><code>]&/0<1 2 3</code></td><td><code>1</code></td></tr>
<tr><td><code>]&/0<1 0 3</code></td><td><code>0</code></td></tr>
</table>

### Conditionals

<table>
<tr><th>Code</th><th>Result</th></tr>
<tr><td><code>](1=1;2;3)</code></td><td><code>2</code></td></tr>
<tr><td><code>](1=2;1 2;3 4)</code></td><td><code>3 4</code></td></tr>
<tr><td><code>]7{w=1;w;a}1</code></td><td><code>1</code></td></tr>
<tr><td><code>]7{w=1;w;a}8</code></td><td><code>7</code></td></tr>
</table>

### Recursion

<table>
<tr><th>Code</th><th>Result</th></tr>
<tr><td><code>]{w=0;0;w+_f(w-1)}6</code></td><td><code>21</code></td></tr>
<tr><td><code>]{w=1;1;w=2;1;(_f(w-2))+_f(w-1)}1:</code></td><td><code>13</code></td></tr>
</table>

### Bindings

<table>
<tr><th>Code</th><th>Result</th></tr>
<tr><td><code>]x+x:7</code></td><td><code>14</code></td></tr>
<tr><td><code>](x:1)+x:2</code></td><td><code>3</code></td></tr>
<tr><td><code>]x+(x:1)+x:2</code></td><td><code>4</code></td></tr>
<tr><td><code>]x+x{x:1+a-w}x:2</code></td><td><code>3</code></td></tr>
</table>

### Note about `]`
The `]` operator is the output operator (taken from [J](http://code.jsoftware.com/wiki/Vocabulary/squarert#monadic)).
It was necessary to add it in order to give more information to the type-inference,
so that the result is closer to what the user expects.

For example consider the `*` operator, it has two interpretations:

* the monadic Head operator: `(vector a) -> a`
* the dyadic multiplication operator: `int -> int -> int` (for brevity, the distributed variants are omitted)

Since `]` only has types: `int -> int` and `(vector int) -> (vector int)`,
then the `*` operator in the expression `]*1 2 3` will be given the monadic type,
since the other type(s) all have higher arity, and so can't be displayed by `]`.

# Conclusion and further ideas
At the end of the day, did I achieve the things I set out to do?
I think yes:

* the compiler both fun and not particularly hard to implement
  (fun times achieved over the vacation and some weekends)
* the syntax became quite K-like, of course there's a lot missing,
  but the struts are in place
* the performance of the [naive Fibonacci is clocking it at 5 seconds](https://gist.github.com/f709b2d94f344398906ce4a5b2926d4a),
  without any particular thought or extra optimization passes

One idea I had even from the start of the project was to
write a [Church encoding](https://en.wikipedia.org/wiki/Church_encoding)-backend
or target something like [unlambda](http://www.madore.org/~david/programs/unlambda/).
But I'll leave that one as an exercise for the reader :D

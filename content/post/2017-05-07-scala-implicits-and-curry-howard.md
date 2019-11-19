---
layout: default
title:  "Scala implicits and the Curry-Howard correspondence"
date:   2017-05-07
aliases: [/main/2017/05/07/scala-implicits-and-curry-howard.html]
categories: main
---

{{< toc >}}

During a discussion at work we stumbled into the topic of best/worst features of
Scala, and it was suggested that the implicit system was the worst feature.

I disagree with this, it might be misunderstood and misused, but far from worst
feature (that has to be the type interference [sic!]). So in order to continue the
tradition of misusing it, I'll present a view of implicits that some might not
have seen or thought of.

The idea is to elucidate the [Curry–Howard correspondence](https://en.wikipedia.org/wiki/Curry%E2%80%93Howard_correspondence)
that's present in Scala's type system, and use implicits to automatically
construct proofs. That this is possible should not be surprising, but what's
interesting is how easy it is.

My motivation for this exercise is that at work we deal a lot more with
business *logic* than with computations. I hear statements such as:
"a user has payed for content, therefore he is entitled to use the content"
rather than "these are the first million prime numbers", and "P implies Q" rather
than numerical properties.

# An explicit Curry-Howard correspondence
The Curry-Howard correspondence is the observation that type-systems can be
thought of as logics (and vice versa). This sounds far harder than it actually
is:

* Propositions correnpond to types
* Implications correspond to functions
* Conjunctions and disjunctions both correspond to simple ADTs (or products and coproducts for the fancy)
* Negations are functions together with a bottom type

Here are some examples motivating this correspondence using Scala and its implicit
system.

## Propositions
A proposition `A` is expressed as a type:
```scala
trait A
```

A proof of proposition `A` is expressed as an inhabitant of the type `A`:
```scala
implicit val proofOfA = new A {}
```

So we can ask the compiler if it can prove `A` using:
```scala
implicitly[A]
```
which would fail with a type-error for unproven propositions:
```scala
trait B
illTyped { "implicitly[B]" }
```
where I've used `illTyped` from [shapeless](https://github.com/milessabin/shapeless/wiki/Feature-overview:-shapeless-2.0.0#testing-for-non-compilation)

## Non-termination
When thinking about computers and proofs, non-termination has to be taken
into account, and we can't trust the type system alone.

Imagine that a mathematician says: "I have a proof of A, I just
have to write it down!" and then never comes back. Do you trust him?
The type system would! Consider this definition:
```scala
@tailrec
def diverge[A](): A = diverge[A]()
```
which makes the expression `diverge()` an inhabitant of any type:
```scala
:t diverge(): Int
:t diverge(): Nothing
```

But as sceptical humans we want to see the actual proof, and so does Scala
at runtime. So when we use `implicitly` to ask for a proof, it's crucial to wait
for the evaluation to succeed.


### Tangent: Exceptions as non-termination
Of course there's a simpler way of inhabiting `Nothing` in Scala, and that's to
`throw`:
```scala
(throw new Exception): Nothing
```
but the point of using `diverge` is that even without resorting to exceptions
it's possible (and easy) to inhabit any type including the bottom type `Nothing`.

### Tangent: Dependently typed systems
Note that in [stronger type systems](https://en.wikipedia.org/wiki/Dependent_type)
more properties can be proven at compile time. For instance [Idris](https://www.idris-lang.org/)
deals with the above example by nothing that `diverge` is not [total](http://docs.idris-lang.org/en/latest/tutorial/theorems.html?highlight=total#sect-totality), and therefore rejects proofs that
uses it with the trade-off that you can trust proofs using only total functions.


## Implications
An implication is expressed as a function:
```scala
implicit def `A implies B`(implicit a: A): B = new B {}
```

Then if we have a proof of `A` in-scope, we can prove `B`:
```scala
implicit val proofOfA = new A {}
implicitly[B]
```
and of-course we can't use `C => D` to prove `D` without a proof of `C`:

```scala
trait C
trait D
implicit def `C implies D`(implicit c: C): D = new D {}
illTyped { """implicitly[C]""" }
illTyped { """implicitly[D]""" }
```

## Conjunction
Conjunction (or `and`) can be expressed using a tuple:
```scala
implicit def `P, Q implies (P and Q)`[P, Q](implicit p: P, q: Q): (P, Q) = (p, q)
```

We can now query if the compiler can prove or conjunction:
```scala
implicit val proofOfA = new A {}
implicit val proofOfB = new B {}
implicitly[(A, B)]
```
and of course when one of the proofs are missing the conjunction can't be proven:
```scala
illTyped { """implicitly[(A, C)]""" }
illTyped { """implicitly[(C, B)]""" }
```

## Disjunction
Disjunction (or `or`) can be expressed using a simple ADT:
```scala
sealed trait Disjunction[T, S]
case class FromT[T, S](t: T) extends Disjunction[T, S]
case class FromS[T, S](s: S) extends Disjunction[T, S]
case class FromTS[T, S](t: T, s: S) extends Disjunction[T, S]
```
accompanied by some implicits to hook it up:
```scala
trait LowPriorityDisjunctionProofs {
  implicit def disjunctionT[T, S](implicit t: T): Disjunction[T, S] = FromT(t)
  implicit def disjunctionS[T, S](implicit s: S): Disjunction[T, S] = FromS(s)
}

object Disjunction extends LowPriorityDisjunctionProofs {
  implicit def disjunctionTS[T, S](implicit t: T, s: S): Disjunction[T, S] = FromTS(t, s)
}
```

Let's see it in action:
```scala
implicit val proofOfA = new A {}
implicit val proofOfB = new B {}
illTyped { "implicitly[C]" }
illTyped { "implicitly[D]" }

implicitly[Disjunction[A, C]]
implicitly[Disjunction[C, B]]
implicitly[Disjunction[A, B]]
illTyped { "implicitly[Disjunction[C, D]]" }
```

### Why not just use `Either`?
Good question, let's see what happens:
```scala
implicit def disjunctionLeft[T, S](implicit t: T): Either[T, S] = Left(t)
implicit def disjunctionRight[T, S](implicit s: S): Either[T, S] = Right(s)
```

This seems to work fine at first
```scala
implicitly[Either[A, C]]
implicitly[Either[C, B]]
```
but this breaks:
```scala
illTyped { "implicitly[Either[A, B]]" }
```
with the clue:
```
<console>:32: error: ambiguous implicit values:
 both method disjunctionLeft of type [T, S](implicit t: T)Either[T,S]
 and method disjunctionRight of type [T, S](implicit s: S)Either[T,S]
 match expected type Either[A,B]
       implicitly[Either[A, B]]
                 ^
```
That is, when Scala finds two ways (with the same priority) of proving
an implicit Scala will not automatically choose for you.

This is the reason for `FromTS` above, and
the trick with putting the implicit in its companion object and
stacking implicits with lower priorities in traits.
I first encountered this idea in [Scalaz](https://github.com/scalaz/scalaz)
and [shapeless](https://github.com/milessabin/shapeless), both libraries
are excellent examples of libraries that uses Scala's features to the fullest
and are big inspirational sources.

## Negation
To express the negation of a proposition `A` one can use the bottom type
`Nothing` to represent the false formula, and define:
```scala
implicit val notA: A => Nothing = { _ => throw new Exception }
```
This encoding relies on observing that `A` and `¬A` is a contraction:
```scala
implicit def `A and ¬A is a contradiction`(implicit a: A, notA: A => Nothing): Nothing = notA(a)
```
When we get a `Nothing` into the implicit system the world becomes quite absurd:
```scala
implicit val proofOfA = new A {}
:t implicitly[B]
:t implicitly[Int]
:t implicitly[Nothing]
```
thankfully the runtime system will not be so lenient and none of
```scala
implicitly[B]
implicitly[Int]
implicitly[Nothing]
```
will terminate (here it'll throw the exception we `new`:ed above).
Note that these typeable expressions will correctly be rejected with a fresh REPL:
```
scala> :t implicitly[Nothing]
<console>:21: error: could not find implicit value for parameter e: Nothing
       implicitly[Nothing]
```

But it is quite fun to sneak really strange expressions past the compiler:
```scala
implicit def `Embrace the nothingness`[P, Q](implicit p: P): Q = implicitly[Nothing]
val b: B = new A {}
val i: Int = b
```
that of course fail at runtime.
[Here's](https://gist.github.com/0f0e8226f1d2adc479cb9fce599f0281) the full code
(using diverge instead) for checking that `scalac` accepts this absurd world.

# Conclusion
Scala's implicit system might be misused and disliked by many. But I think it's
one of the more interesting features of Scala, and my preferred view of it is that
it's a readily available proof engine embedded into the language.

A down to earth usage that is encountered frequently in the wild are typeclasses
for JSON-codecs.
Since typeclasses are implemented in Scala as implicits, when handed the
evidence that a type `A` has a `ToJSON` typeclass instance by `implicitly`, that
evince can be a constructive proof, a cookbook, of a way to convert a value of type
`A` to JSON.

Examples of this can be seen for instance in [Argonaut](http://argonaut.io/) and it's
[cats](https://github.com/typelevel/cats) based fork [circe](https://github.com/circe/circe),
and in [spray-json](https://github.com/spray/spray-json) with its obligatory companion
[spray-json-shapeless](https://github.com/fommil/spray-json-shapeless).
(I can't but suspect they are inspired by the excellent [aeson](https://hackage.haskell.org/package/aeson-1.2.0.0/docs/Data-Aeson.html) library, but I might be biased towards Haskell in general.)

---
layout: default
title: "Combining Brick and Haskeline"
date: 2017-08-31
aliases: [/main/2017/08/31/combining-brick-and-haskeline.html]
categories: main
---
{{< toc >}}

I recently wrote [an interpreter of a stack-based language in Haskell](https://github.com/rootmos/silly-joy)
and wanted to give its REPL command-line editing and history.

The best way to do so without effort is to use the fantastic
[rlwrap](https://github.com/hanslub42/rlwrap): it handles the readline
integration for you and lets you focus on your own problem domain.

I wanted to show the user the current stack in the interpreter and ended up
with:
![haskeline-brick screenshot](haskeline-brick-silly-joy.gif)

This was inspired by `gdb -tui`:
![gdb's tui](gdb-tui.png)

Here rlwrap falls short, it's not intended to wrap anything more complicated
than a user interface that writes a prompt to stdout and reads a line from
stdin.

I started to look for alternatives to `rlwrap` and settled on
[Brick](https://hackage.haskell.org/package/brick) for handling the terminal
user interface and
[Haskeline](https://hackage.haskell.org/package/haskeline) for providing
the command-line functionality.

However, Haskeline needed some coaxing to play nice with Brick.
The code can be found [in my fork of Haskeline](https://github.com/rootmos/haskeline).

# Brick
[Brick](https://hackage.haskell.org/package/brick) is a library for
declaratively building terminal user interfaces.

This means it lets you express your wishes about how the layout
of the interface's widgets should be placed and decorated,
without having to bother with control characters or ncurses.

To get up to speed on how to use it I followed mainly:

* the [User guide](https://github.com/jtdaugherty/brick/blob/master/docs/guide.rst),
* its [Hackage documentation](https://hackage.haskell.org/package/brick)
* and the [Introduction to Brick](https://samtay.github.io/articles/brick.html)
  post implementing a snake game. This was also the post that brought Brick to
  my attention, thank you [samtay](https://github.com/samtay) for that!

# Haskeline
[Haskeline](https://hackage.haskell.org/package/haskeline) is a pure Haskell
implementation providing similar functionality as [readline](http://cnswww.cns.cwru.edu/php/chet/readline/rltop.html):
command-line editing, history and completion.
You've probably already seen it in action since it's used in GHCi.

It already featured multiple backends for different kinds of terminals (e.g.
Windows or POSIX), so adding another felt natural.
Since both Brick and Haskeline are event driven, combining them amounts to two
channels in opposite directions,
[not exactly brain surgery.](https://youtu.be/THNPmhBl-8I)
Also, Haskeline is implemented in the style of monad transformer stacks,
so it provides an example on how to structure a code base using them.

## Hidden gem
While implementing the Brick backend in Haskeline,
[I encountered this](https://github.com/judah/haskeline/blob/d5ef581a19218b96946921c5f092bafe1739e30b/System/Console/Haskeline/Term.hs#L86)
curious looking type:
```haskell
data EvalTerm m =
    forall n . (Term n, CommandMonad n)
            => EvalTerm (forall a . n a -> m a) (forall a . m a -> n a)
```
This type is used when specifying how to run a terminal backend,
where in the [`TermOps`](https://github.com/judah/haskeline/blob/d5ef581a19218b96946921c5f092bafe1739e30b/System/Console/Haskeline/Term.hs#L41)
the following field is required:
```haskell
evalTerm :: forall m . CommandMonad m => EvalTerm m
```

To unravel the meaning of the `EvalTerm` type, note that it's an
[existential type](https://wiki.haskell.org/Existential_type).
Another clue is to simplify it a bit using the
[`~>` type operator](https://hackage.haskell.org/package/natural-transformation-0.4/docs/Control-Natural.html#t:-126--62-):
```haskell
type f ~> g = forall x. f x -> g x
```

Using this type synonym, `EvalTerm` contains both a transformation
`n ~> m` and another in the reverse direction `m ~> n`.
Did someone say [natural isomorphism](https://ncatlab.org/nlab/show/natural+isomorphism)?

Note also that in `evalTerm` both `m` and `n` have `CommandMonad` instances,
while `n` also has a `Term` instance.
Having the picture of monad stacks in your mind suggests that `n` might be
constructed as one or more monad transformers on top of `m`.

Since these backends have different requirements, i.e. implemented
with different monad stacks, there's a need for abstraction.
Can you see the sparkle in the eye of the OO-programmer thinking about
interfaces and inheritance?
Indeed, the [dynamic dispatch mechanism of OOP](https://wiki.haskell.org/Existential_type#Dynamic_dispatch_mechanism_of_OOP)
can be emulated using existential types, but here we'll abstract monads
not the data itself, but the idea and underlying mechanism are very much the
same.

## Example of abstracting monads
To check my hypothesis of the interpretation of the `EvalTerm` type above,
i.e. as a way to talk explicitly about abstractions and providing witnessing
values representing concrete implementations,
[I wrote down the following example](http://gist.github.com/rootmos/1b413f619a651e618d8c4b15ae3c1f8a).

Assume we have a type class that we would like to provide different
implementations of:
```haskell
class Interface m where
    suchFunction :: Int -> m Int
```

We also have a "baseline" monad class, representing the context in which we
wish to use the abstracted interface:
```haskell
class MonadIO m => BaseMonad m where
    baseOutput :: String -> m ()
    baseOutput = liftIO . putStrLn
```

Next, let's write down the type representing the dynamic dispatch of calls to
the interface class into a particular concrete implementation:
```haskell
newtype Dispatch = MkDispatch (forall m . BaseMonad m => Concretization m)

data Concretization m =
    forall n . (Interface n, Monad n) => MkConcretization (n ~> m) (m ~> n)
```
The separate `Concretization` data type is put at the top-level for
no other reason than that I haven't found a way to bake it into the
`Dispatch` type.
Naively I tried to inline it:
```haskell
data Dispatch2 where
    MkDispatch2 :: Monad m => (forall n . (Interface n, Monad n) => ((m ~> n), (n ~> m))) -> Dispatch2
```
but GHC told me:
```
    • Illegal polymorphic type: m ~> n
      GHC doesn't yet support impredicative polymorphism
```

Back to the example, I added three different `Dispatch` values.
First one using a `ReaderT Int`:
```haskell
newtype Concrete1 m a = MkConcrete1 { runConcrete1 :: ReaderT Int m a }
    deriving (Monad, Applicative, Functor, MonadReader Int)

instance Monad m => Interface (Concrete1 m) where
    suchFunction i = do
        x <- ask
        return $ x + i

dispatch1 :: Int -> Dispatch
dispatch1 i = MkDispatch $
    MkConcretization ((flip runReaderT) i . runConcrete1) (MkConcrete1 . lift)
```

Secondly, one using a `StateT Int`, mainly showing that you can
easily have different monad stacks on top of a common base:
```haskell
newtype Concrete2 m a = MkConcrete2 { runConcrete2 :: StateT Int m a }
    deriving (Monad, Applicative, Functor, MonadState Int)

instance Monad m => Interface (Concrete2 m) where
    suchFunction i = do
        x <- get
        put $ x * i
        return $ x * i

dispatch2 :: Int -> Dispatch
dispatch2 i = MkDispatch $
    MkConcretization ((flip evalStateT) i . runConcrete2) (MkConcrete2 . lift)
```

Lastly, an example using a free monad with the intent of showing that the
concrete monad does not necessarily need to be a monad transformer on top of
the base monad.
However, the example below suggests something similar to a `FreeT`.
[The actual `FreeT`](https://hackage.haskell.org/package/free-4.12.4/docs/Control-Monad-Trans-Free.html#t:FreeT)
is different.

It's possible to implement mtl-style instances,
lifting through the underlying `BaseMonad`.
[Here is the corresponding example](https://gist.github.com/929028e52ca8e10686a6d1214dedc70b)
using that style.
In that setting the second field of `MkConcretization` is unnecessary:
the lifting `m ~> n` transform is used implicitly by the `MonadIO` and
`BaseMonad` instances of the concrete implementations.
As always there's a trade-off and matter of taste.

Anyway, here's the code for the third concretization:
```haskell
data Concrete3F m v where
    SomeFunctionF :: Int -> (Int -> v) -> Concrete3F m v
    LiftF :: forall a m v . (m a) -> (a -> v) -> Concrete3F m v

instance Functor (Concrete3F m) where
    fmap f (SomeFunctionF i k) = SomeFunctionF i (f . k)
    fmap f (LiftF ma k) = LiftF ma (f . k)

newtype Concrete3 m a = MkConcrete3 { runConcrete3 :: Free (Concrete3F m) a }
    deriving (Monad, Applicative, Functor)

instance Interface (Concrete3 m) where
    suchFunction i = MkConcrete3 . liftF $ SomeFunctionF i id

dispatch3 :: Dispatch
dispatch3 = MkDispatch $ MkConcretization
    (iterM go . runConcrete3)
    (MkConcrete3 . liftF . \ma -> LiftF ma id)

go :: BaseMonad m => Concrete3F m (m v) -> m v
go (SomeFunctionF i k) = k (i * i)
go (LiftF ma k) = ma >>= k
```

To show how the usage of `Dispatch` would work, here are some example programs:
```haskell
program1 :: (Interface n, Monad n, BaseMonad m) => (m ~> n) -> n Int
program1 liftB = do
    i <- suchFunction 1
    liftB $ baseOutput $ "Interface: program1 " ++ show i
    return i

program2 :: BaseMonad m => Int -> m ()
program2 i = do
    baseOutput $ "BaseMonad: program2 " ++ show i

program3 :: BaseMonad m => Dispatch -> m ()
program3 (MkDispatch (MkConcretization evalI liftB)) = do
    l <- evalI $ do
        i <- suchFunction 2
        j <- program1 liftB
        let k = i + j
        liftB $ program2 k
        return $ k
    baseOutput $ "BaseMonad again l=" ++ show l
```
Note that:

* `program1` does not make any assumption on the relation between `n` and `m`,
  so uses of `BaseMonad` functions requires a lift
* `program2` only uses `m` (the `BaseMonad`) and so requires to be lifted
  into `m` in `program3`
* `program3` shows an inner do-expression than runs in the `n` monad, and
  so needs to be evaluated back down into the `m` monad


# Example usage (aka: just show me how to use it)

This example will set up a simple two widget Brick app, with a simple
text string on top and a Haskeline input loop on the bottom:

![demo](haskeline-brick-demo.gif)

The code of this example
[is included in the fork](https://github.com/rootmos/haskeline/blob/master/examples/brick-haskeline.hs)
and can be executed using
[the accompanying Makefile-script](https://github.com/rootmos/haskeline/blob/master/run-brick-haskeline-example.sh).

```haskell
data Event = FromHBWidget HB.ToBrick | HaskelineDied (Either SomeException ())

data Name = TheApp | HaskelineWidget
    deriving (Ord, Eq, Show)

data MyState = MyState { haskelineWidget :: HB.Widget Name }

app :: HB.Config Event -> App MyState Event Name
app c = App { appDraw = drawUI
            , appChooseCursor = const $ showCursorNamed HaskelineWidget
            , appHandleEvent = handleEvent c
            , appStartEvent = return
            , appAttrMap = const $ attrMap V.defAttr []
            }

handleEvent :: HB.Config Event
            -> MyState -> BrickEvent Name Event -> EventM Name (Next MyState)
handleEvent c s@MyState{haskelineWidget = hw} e = do
    hw' <- HB.handleEvent c hw e
    handleAppEvent (s { haskelineWidget = hw' }) e

handleAppEvent :: MyState -> BrickEvent Name Event -> EventM Name (Next MyState)
handleAppEvent s (AppEvent (HaskelineDied e)) = halt s
handleAppEvent s (VtyEvent (V.EvKey V.KEsc [])) = halt s
handleAppEvent s _ = continue s

drawUI :: MyState -> [Widget Name]
drawUI s = [ top <=> bottom ]
    where
        top = C.center $ str "yo"
        bottom = B.border $ HB.render (haskelineWidget s)

runHaskeline :: HB.Config Event -> IO ()
runHaskeline c = runInputTBehavior (HB.useBrick c) defaultSettings loop
   where
       loop :: InputT IO ()
       loop = do
           minput <- getInputLine "% "
           case minput of
             Nothing -> return ()
             Just input -> do
                 outputStr input
                 loop

main :: IO ()
main = do
    chan <- newBChan 10
    config <- HB.configure
            chan
            FromHBWidget
            (\case { FromHBWidget x -> Just x; _ -> Nothing })
    _ <- forkFinally
            (runHaskeline config)
            (writeBChan chan . HaskelineDied)
    void $ customMain
        (V.mkVty V.defaultConfig)
        (Just chan)
        (app config)
        MyState { haskelineWidget = HB.initialWidget HaskelineWidget }
```

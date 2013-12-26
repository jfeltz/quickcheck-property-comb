quickcheck-property-comb
--------
These are combinators, based on the Reader and Writer Monads, to allow for fast
and painless Quickcheck property/invariant construction.

Why?
----
[Quickcheck](http://hackage.haskell.org/package/QuickCheck) is a tool used to
test cases based on constructed Properties, or essentially functions taking a
data structure and returning a boolean True or False. 

However when running tests, the only way to document their failing case
is through labeling them after binding, e.g.: 

```haskell
inv1, inv2, inv3 :: Foo -> Bool 
..
fooInvariants :: Foo -> Property 
fooInvariants f = 
    conjoin . map property $ 
      conjoin $ zipWith toLabeled
        ["foo should be even", "foo should contain 3 bar", "all bar should not equal foo"] 
        [inv1 f, inv2 f, inv3 f]
```

This gets unwieldy fast as the complexity of the data-structure increases, so
quickcheck-property-comb provides the following:
  - Monadically unifies composition of invariants and the documenting of those invariants for determining cause of failure.
  - Effective diagnostics for invariants with changing post-conditions,
    leading to <b>faster cause-of-failure diagnosis</b>.

Example use
-----------
See example in cabal package description.

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
      conjoin $ zipWith toPrintTestCase
        ["foo should be even", "foo should contain 3 bar", "all bar should not equal foo"] 
        [inv1 f, inv2 f, inv3 f]
```

This gets unwieldy fast as the complexity of the data-structure increases, so
quickcheck-property-comb monidically allows the composition of invariants and 
the documenting of those invariants for determining cause of failure.

Example use
-----------
See example in cabal package description.
```haskell
   data (Ord l) => Consumers l =
     Consumers {
       introduced :: S.Set l,
       met :: M.Map (S.Set l) Bool,
       disjoints :: Disjoints l
     }
  
   disjoints_odds ::  Inv (Disjoints l)
   disjoints_odds = do
    doc "no odd sets in disjoints"
    disjoint_sets <- cause 
    ..
    return False
  
   disjoints_non_singletons :: Inv (Disjoints l)
   disjoints_non_singletons = do
     ..
     return True
  
   disjoints_inv :: Invariants (Disjoints l)
   disjoints_inv= do
     sat disjoints_odds
     sat disjoints_non_singletons
  
   introduced_in_disjoint :: Inv (Consumers l)
   introduced_in_disjoint = do
     doc "all at quantity are a singleton subset in disjoints"
     subsets       <- (map S.singleton) . S.toList . introduced <$> cause
     disjoint_sets <- disjoints <$> cause
     doc $ "  failing sets:" ++ show disjoint_sets
     return . and . map ((flip S.member) disjoint_sets) $ subsets
   
   inv_consumers :: Invariants (Consumers l)
   inv_consumers = do
     satcomp disjoints disjoints_inv
     satcomp met met_inv
     sat introduced_in_disjoint
```
  And to run the invariants on generated cases:
```
  prop_testedFunction :: Arg -> Property
  prop_testedFunction arg = 
  let consumers = testedFunction arg in
  runInvariants consumers inv_consumers
```

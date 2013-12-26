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
```haskell
data (Ord l) => QuantityConsumers l =
  QuantityConsumers {
    atQuantity :: S.Set l,
    qcMet :: M.Map (S.Set l) Bool,
    qcDisjoints :: Disjoints l
  }

disjoint_sizes ::  Inv (Disjoints l)
disjoint_sizes = do
  doc . unlines $
    [
     "the intersection of all at quantity and disjoints are the only allowed",
     "singleton sets in disjoints"
    ]
  disjoints <- cause 
  -- Do some checking on disjoints 
  return False

disjoints_eq :: Inv (Disjoints l)
disjoints_eq = do
  doc "the solution state domain and sets formed by partition are equal"
  ..
  return False

disjoints :: Invariants (Disjoints l)
disjoints = do
  sat disjoints_eq
  sat disjoints_sizes

at_quantity_in_disjoint :: Inv (QuantityConsumers l)
at_quantity_in_disjoint = do
  doc "all at quantity are a singleton subset in disjoints"

  subsets       <- (map S.singleton) . S.toList . atQuantity <$> cause
  disjoint_sets <- fromDisjoints <$>  cause

  return . and . map ((flip S.member) disjoint_sets) $ subsets

inv_quantity_consumers :: Invariants (QuantityConsumers l)
inv_quantity_consumers = do
  satcomp qcDisjoints disjoints
  sat at_quantity_in_disjoint

-- Then to create the final property
prop_quantity_consumers :: QuantityConsumers l -> Property
prop_quantity_consumers q = runInvariants q inv_quantity_consumers
```

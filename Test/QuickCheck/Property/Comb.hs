-- TODO in some cases it may be useful to indent  messages
-- based on a documented "context" above them

{-# LANGUAGE TupleSections,  ScopedTypeVariables, GeneralizedNewtypeDeriving #-}
module Test.QuickCheck.Property.Comb (
  cause, Inv, Invariants, doc, sat, satcomp, runInv, runInvariants
  ) where
import Test.QuickCheck
import Control.Monad.Writer
import Control.Monad.Reader

-- A Monad which collects related invariants on the input
type InvM c r = ReaderT c (Writer String) r
type Inv c = InvM c Bool

cause :: (Monad m) => ReaderT c m c
cause = ask

-- A Monad which collects invariants on the input
type Invariants c = ReaderT c (Writer [Inv c]) ()

doc :: String -> InvM r ()
doc = lift . tell

sat :: Inv c -> Invariants c
sat p = lift . tell $ [p]

satcomp :: forall c c'. (c' -> c) -> Invariants c -> Invariants c'
satcomp f = mapReaderT toWriter . withReaderT f where
  toWriter :: Writer [Inv c] () -> Writer [Inv c'] ()
  toWriter = mapWriter (((),) . map toPredicate . snd)
  toPredicate :: Inv c -> Inv c'
  toPredicate = withReaderT f

runInv :: (Show c) => c -> Inv c -> Property
runInv checked rdr =
  let (effect, msg) = runWriter . runReaderT rdr $ checked in
    printTestCase ("invariant: " ++ if null msg then "unknown" else msg)
      . property $ effect

runInvariants :: (Show c) => c -> Invariants c -> Property
runInvariants checked preds =
  conjoin . map (runInv checked) . execWriter . runReaderT preds $ checked

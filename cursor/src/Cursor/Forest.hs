{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE RecordWildCards #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE DeriveFunctor #-}

module Cursor.Forest
    ( ForestCursor(..)
    , makeForestCursor
    , rebuildForestCursor
    , forestCursorListCursorL
    , forestCursorSelectedTreeL
    , forestCursorSelectPrevTree
    , forestCursorSelectNextTree
    , forestCursorSelectFirstTree
    , forestCursorSelectLastTree
    , forestCursorSelection
    , forestCursorSelectIndex
    , forestCursorInsert
    , forestCursorAppend
    , forestCursorInsertAndSelect
    , forestCursorAppendAndSelect
    , forestCursorAddChildToNodeAtPos
    , forestCursorAddChildToNodeAtStart
    , forestCursorAddChildToNodeAtEnd
    , forestCursorRemoveTreeAndSelectPrev
    , forestCursorDeleteTreeAndSelectNext
    , forestCursorRemoveTree
    , forestCursorDeleteTree
    , forestCursorAddRoot
    ) where

import GHC.Generics (Generic)

import Data.Validity
import Data.Validity.Tree ()

import qualified Data.List.NonEmpty as NE
import Data.List.NonEmpty (NonEmpty)
import Data.Tree

import Lens.Micro

import Cursor.NonEmpty
import Cursor.Tree

newtype ForestCursor a = ForestCursor
    { forestCursorListCursor :: NonEmptyCursor (TreeCursor a)
    } deriving (Show, Eq, Generic, Functor)

instance Validity a => Validity (ForestCursor a)

makeForestCursor :: NonEmpty (Tree a) -> ForestCursor a
makeForestCursor = ForestCursor . makeNonEmptyCursor . NE.map makeTreeCursor

rebuildForestCursor :: ForestCursor a -> NonEmpty (Tree a)
rebuildForestCursor =
    NE.map rebuildTreeCursor . rebuildNonEmptyCursor . forestCursorListCursor

forestCursorListCursorL ::
       Lens' (ForestCursor a) (NonEmptyCursor (TreeCursor a))
forestCursorListCursorL =
    lens forestCursorListCursor $ \fc lc -> fc {forestCursorListCursor = lc}

forestCursorSelectedTreeL :: Lens' (ForestCursor a) (TreeCursor a)
forestCursorSelectedTreeL = forestCursorListCursorL . nonEmptyCursorElemL

forestCursorSelectPrevTree :: ForestCursor a -> Maybe (ForestCursor a)
forestCursorSelectPrevTree = forestCursorListCursorL nonEmptyCursorSelectPrev

forestCursorSelectNextTree :: ForestCursor a -> Maybe (ForestCursor a)
forestCursorSelectNextTree = forestCursorListCursorL nonEmptyCursorSelectNext

forestCursorSelectFirstTree :: ForestCursor a -> ForestCursor a
forestCursorSelectFirstTree =
    forestCursorListCursorL %~ nonEmptyCursorSelectFirst

forestCursorSelectLastTree :: ForestCursor a -> ForestCursor a
forestCursorSelectLastTree = forestCursorListCursorL %~ nonEmptyCursorSelectLast

forestCursorSelection :: ForestCursor a -> Int
forestCursorSelection fc =
    nonEmptyCursorSelection $ fc ^. forestCursorListCursorL

forestCursorSelectIndex :: ForestCursor a -> Int -> Maybe (ForestCursor a)
forestCursorSelectIndex fc i =
    fc & forestCursorListCursorL (`nonEmptyCursorSelectIndex` i)

forestCursorInsert :: ForestCursor a -> TreeCursor a -> ForestCursor a
forestCursorInsert fc tc =
    fc & forestCursorListCursorL %~ nonEmptyCursorInsert tc

forestCursorInsertAndSelect :: ForestCursor a -> TreeCursor a -> ForestCursor a
forestCursorInsertAndSelect fc tc =
    fc & forestCursorListCursorL %~ nonEmptyCursorInsertAndSelect tc

forestCursorAppend :: ForestCursor a -> TreeCursor a -> ForestCursor a
forestCursorAppend fc tc =
    fc & forestCursorListCursorL %~ nonEmptyCursorAppend tc

forestCursorAppendAndSelect :: ForestCursor a -> TreeCursor a -> ForestCursor a
forestCursorAppendAndSelect fc tc =
    fc & forestCursorListCursorL %~ nonEmptyCursorAppendAndSelect tc

forestCursorAddChildToNodeAtPos ::
       Int -> Tree a -> ForestCursor a -> ForestCursor a
forestCursorAddChildToNodeAtPos i t fc =
    fc & forestCursorSelectedTreeL %~ treeCursorAddChildAtPos i t

forestCursorAddChildToNodeAtStart :: Tree a -> ForestCursor a -> ForestCursor a
forestCursorAddChildToNodeAtStart t fc =
    fc & forestCursorSelectedTreeL %~ treeCursorAddChildAtStart t

forestCursorAddChildToNodeAtEnd :: Tree a -> ForestCursor a -> ForestCursor a
forestCursorAddChildToNodeAtEnd t fc =
    fc & forestCursorSelectedTreeL %~ treeCursorAddChildAtEnd t

forestCursorRemoveTreeAndSelectPrev :: ForestCursor a -> Maybe (ForestCursor a)
forestCursorRemoveTreeAndSelectPrev =
    forestCursorListCursorL nonEmptyCursorRemoveElemAndSelectPrev

forestCursorDeleteTreeAndSelectNext :: ForestCursor a -> Maybe (ForestCursor a)
forestCursorDeleteTreeAndSelectNext =
    forestCursorListCursorL nonEmptyCursorDeleteElemAndSelectNext

forestCursorRemoveTree :: ForestCursor a -> Maybe (ForestCursor a)
forestCursorRemoveTree = forestCursorListCursorL nonEmptyCursorRemoveElem

forestCursorDeleteTree :: ForestCursor a -> Maybe (ForestCursor a)
forestCursorDeleteTree = forestCursorListCursorL nonEmptyCursorDeleteElem

forestCursorAddRoot :: ForestCursor a -> a -> TreeCursor a
forestCursorAddRoot fc v =
    makeTreeCursor $ Node v $ NE.toList $ rebuildForestCursor fc
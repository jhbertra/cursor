{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RankNTypes #-}
{-# LANGUAGE TypeApplications #-}

module Cursor.TextSpec
  ( spec,
  )
where

import Control.Monad
import Cursor.List
import Cursor.Text
import Cursor.Text.Gen
import Cursor.Types
import Data.Char
import Data.List
import Data.Text (Text)
import qualified Data.Text as T
import Test.Hspec
import Test.QuickCheck
import Test.Validity

spec :: Spec
spec = do
  eqSpec @TextCursor
  genValidSpec @TextCursor
  describe "Validity TextCursor" $ do
    it "considers a text cursor with a newline in the previous characters invalid"
      $ shouldBeInvalid
      $ TextCursor {textCursorList = ListCursor {listCursorPrev = "\n", listCursorNext = ""}}
    it "considers a text cursor with a newline in the next characters invalid"
      $ shouldBeInvalid
      $ TextCursor {textCursorList = ListCursor {listCursorPrev = "", listCursorNext = "\n"}}
    it "considers a text cursor with an unsafe character in the previous characters invalid"
      $ shouldBeInvalid
      $ TextCursor {textCursorList = ListCursor {listCursorPrev = "\55810", listCursorNext = ""}}
    it "considers a text cursor with an unsafe character in the next characters invalid"
      $ shouldBeInvalid
      $ TextCursor {textCursorList = ListCursor {listCursorPrev = "\55810", listCursorNext = "\n"}}
  describe "emptyTextCursor" $ it "is valid" $ shouldBeValid emptyTextCursor
  describe "makeTextCursor"
    $ it "produces valid list cursors"
    $ producesValidsOnValids makeTextCursor
  describe "makeTextCursorWithSelection"
    $ it "produces valid list cursors"
    $ producesValidsOnValids2 makeTextCursorWithSelection
  describe "rebuildTextCursor" $ do
    it "produces valid lists" $ producesValidsOnValids rebuildTextCursor
    it "is the inverse of makeTextCursor" $
      inverseFunctionsIfFirstSucceedsOnValid makeTextCursor rebuildTextCursor
    it "is the inverse of makeTextCursorWithSelection for any index"
      $ forAllUnchecked
      $ \i ->
        inverseFunctionsIfFirstSucceedsOnValid (makeTextCursorWithSelection i) rebuildTextCursor
  describe "textCursorNull" $ it "produces valid bools" $ producesValidsOnValids textCursorNull
  describe "textCursorLength" $ it "produces valid ints" $ producesValidsOnValids textCursorLength
  describe "textCursorIndex" $ it "produces valid indices" $ producesValidsOnValids textCursorIndex
  describe "textCursorSelectPrev" $ do
    it "produces valid cursors" $ producesValidsOnValids textCursorSelectPrev
    it "is a movement" $ isMovementM textCursorSelectPrev
    it "selects the previous position" pending
  describe "textCursorSelectNext" $ do
    it "produces valid cursors" $ producesValidsOnValids textCursorSelectNext
    it "is a movement" $ isMovementM textCursorSelectNext
    it "selects the next position" pending
  describe "textCursorSelectIndex" $ do
    it "produces valid cursors" $ producesValidsOnValids2 textCursorSelectIndex
    it "is a movement" $ forAllUnchecked $ \ix -> isMovement (textCursorSelectIndex ix)
    it "selects the position at the given index" pending
    it "produces a cursor that has the given selection for valid selections in the cursor"
      $ forAllValid
      $ \tc ->
        forAll (choose (0, textCursorLength tc)) $ \i ->
          textCursorIndex (textCursorSelectIndex i tc) `shouldBe` i
  describe "textCursorSelectStart" $ do
    it "produces valid cursors" $ producesValidsOnValids textCursorSelectStart
    it "is a movement" $ isMovement textCursorSelectStart
    it "is idempotent" $ idempotent textCursorSelectStart
    it "selects the starting position" pending
  describe "textCursorSelectEnd" $ do
    it "produces valid cursors" $ producesValidsOnValids textCursorSelectEnd
    it "is a movement" $ isMovement textCursorSelectEnd
    it "is idempotent" $ idempotent textCursorSelectEnd
    it "selects the end position" pending
  describe "textCursorPrevChar" $ do
    it "produces valid items" $ producesValidsOnValids textCursorPrevChar
    it "returns the item before the position" pending
  describe "textCursorNextChar" $ do
    it "produces valid items" $ producesValidsOnValids textCursorNextChar
    it "returns the item after the position" pending
  describe "textCursorSelectBeginWord" $ do
    it "produces valid items" $ producesValidsOnValids textCursorSelectBeginWord
    it "is a movement" $ isMovement textCursorSelectBeginWord
    it "is idempotent" $ isIdempotentForSentence textCursorSelectBeginWord
    it "works for this example" $
      textCursorSelectBeginWord (buildTestTextCursor "hell" "o") `shouldBe` buildTestTextCursor "" "hello"
    it "works for this example" $
      textCursorSelectBeginWord (buildTestTextCursor "hello  " " world") `shouldBe` buildTestTextCursor "" "hello   world"
    it "works for this example" $
      textCursorSelectBeginWord (buildTestTextCursor "hello " "world") `shouldBe` buildTestTextCursor "hello " "world"
    it "works for this example" $
      textCursorSelectBeginWord (buildTestTextCursor "" " hello") `shouldBe` buildTestTextCursor "" " hello"
  describe "textCursorSelectEndWord" $ do
    it "produces valid items" $ producesValidsOnValids textCursorSelectEndWord
    it "is a movement" $ isMovement textCursorSelectEndWord
    it "is idempotent" $ isIdempotentForSentence textCursorSelectEndWord
    it "works for this example" $
      textCursorSelectEndWord (buildTestTextCursor "hell" "o") `shouldBe` buildTestTextCursor "hello" ""
    it "works for this example" $
      textCursorSelectEndWord (buildTestTextCursor "hello  " " world") `shouldBe` buildTestTextCursor "hello   world" ""
    it "works for this example" $
      textCursorSelectEndWord (buildTestTextCursor "hello" " world") `shouldBe` buildTestTextCursor "hello" " world"
    it "works for this example" $
      textCursorSelectEndWord (buildTestTextCursor "hello " "") `shouldBe` buildTestTextCursor "hello " ""
  describe "textCursorSelectNextWord" $ do
    it "produces valid items" $ producesValidsOnValids textCursorSelectNextWord
    it "is a movement" $ isMovement textCursorSelectNextWord
    it "works for this example" $
      textCursorSelectNextWord (buildTestTextCursor "" "hello") `shouldBe` buildTestTextCursor "hello" ""
    it "works for this example" $
      textCursorSelectNextWord (buildTestTextCursor "hell" "o world") `shouldBe` buildTestTextCursor "hello " "world"
    it "works for this example" $
      textCursorSelectNextWord (buildTestTextCursor "hello" " world") `shouldBe` buildTestTextCursor "hello " "world"
    it "works for this example" $
      textCursorSelectNextWord (buildTestTextCursor "hello " "") `shouldBe` buildTestTextCursor "hello " ""
    it "goes to the end of the cursor" $
      textCursorSelectNextWord (buildTestTextCursor "a\v" "b") `shouldBe` buildTestTextCursor "a\vb" ""
    it "chooses the next word correctly" $
      textCursorSelectNextWord (buildTestTextCursor "a" " b c") `shouldBe` buildTestTextCursor "a " "b c"
  describe "textCursorSelectPrevWord" $ do
    it "produces valid items" $ producesValidsOnValids textCursorSelectPrevWord
    it "is a movement" $ isMovement textCursorSelectPrevWord
    it "works for this example" $
      textCursorSelectPrevWord (buildTestTextCursor "hello" "") `shouldBe` buildTestTextCursor "" "hello"
    it "works for this example" $
      textCursorSelectPrevWord (buildTestTextCursor "hello w" "orld") `shouldBe` buildTestTextCursor "hello" " world"
    it "works for this example" $
      textCursorSelectPrevWord (buildTestTextCursor "hello " "world") `shouldBe` buildTestTextCursor "hello" " world"
    it "works for this example" $
      textCursorSelectPrevWord (buildTestTextCursor " h" "ello") `shouldBe` buildTestTextCursor "" " hello"
    it "goes to the beginning of the cursor" $
      textCursorSelectPrevWord (buildTestTextCursor "a" "\vb") `shouldBe` buildTestTextCursor "" "a\vb"
    it "chooses the previous word correctly" $
      textCursorSelectPrevWord (buildTestTextCursor "a b" " c") `shouldBe` buildTestTextCursor "a" " b c"
  describe "textCursorInsert" $ do
    it "produces valids" $ forAllValid $ \d -> producesValidsOnValids (textCursorInsert d)
    it "inserts an item before the cursor" pending
  describe "textCursorAppend" $ do
    it "produces valids" $ forAllValid $ \d -> producesValidsOnValids (textCursorAppend d)
    it "inserts an item after the cursor" pending
  describe "textCursorInsertString" $ do
    it "produces valids" $ forAllValid $ \d -> producesValidsOnValids (textCursorInsertString d)
    it "works for this example" $
      (makeTextCursor "hello" >>= textCursorInsertString " world")
        `shouldBe` makeTextCursor "hello world"
  describe "textCursorAppendString"
    $ it "produces valids"
    $ forAllValid
    $ \d -> producesValidsOnValids (textCursorAppendString d)
  describe "textCursorInsertText"
    $ it "produces valids"
    $ forAllValid
    $ \d -> producesValidsOnValids (textCursorInsertText d)
  describe "textCursorAppendText"
    $ it "produces valids"
    $ forAllValid
    $ \d -> producesValidsOnValids (textCursorAppendText d)
  describe "textCursorRemove" $ do
    it "produces valids" $ validIfSucceedsOnValid textCursorRemove
    isRemove textCursorRemove
    it "removes an item before the cursor"
      $ forAllValid
      $ \tc -> case textCursorRemove tc of
                Just (Updated (TextCursor (ListCursor p _))) ->
                  p `shouldBe` tail (textCursorPrev tc)
                _ -> pure ()
  describe "textCursorDelete" $ do
    it "produces valids" $ validIfSucceedsOnValid textCursorDelete
    isDelete textCursorDelete
    it "removes an item before the cursor"
      $ forAllValid
      $ \tc -> case textCursorDelete tc of
                Just (Updated (TextCursor (ListCursor _ n))) ->
                  n `shouldBe` tail (textCursorNext tc)
                _ -> pure ()
  describe "textCursorSelectBeginWord" $ do
    it "produces valid items" $ producesValidsOnValids textCursorSelectBeginWord
    it "is idempotent" $ isIdempotentForSentence textCursorSelectBeginWord
    it "works for this example" $
      textCursorSelectBeginWord (buildTestTextCursor "hell" "o") `shouldBe` buildTestTextCursor "" "hello"
    it "works for this example" $
      textCursorSelectBeginWord (buildTestTextCursor "hello  " " world") `shouldBe` buildTestTextCursor "" "hello   world"
    it "works for this example" $
      textCursorSelectBeginWord (buildTestTextCursor "hello " "world") `shouldBe` buildTestTextCursor "hello " "world"
    it "works for this example" $
      textCursorSelectBeginWord (buildTestTextCursor "" " hello") `shouldBe` buildTestTextCursor "" " hello"
  describe "textCursorSelectEndWord" $ do
    it "produces valid items" $ producesValidsOnValids textCursorSelectEndWord
    it "is a movement" $ isMovement textCursorSelectEndWord
    it "is idempotent" $ isIdempotentForSentence textCursorSelectEndWord
    it "works for this example" $
      textCursorSelectEndWord (buildTestTextCursor "hell" "o") `shouldBe` buildTestTextCursor "hello" ""
    it "works for this example" $
      textCursorSelectEndWord (buildTestTextCursor "hello  " " world") `shouldBe` buildTestTextCursor "hello   world" ""
    it "works for this example" $
      textCursorSelectEndWord (buildTestTextCursor "hello" " world") `shouldBe` buildTestTextCursor "hello" " world"
    it "works for this example" $
      textCursorSelectEndWord (buildTestTextCursor "hello " "") `shouldBe` buildTestTextCursor "hello " ""
  describe "textCursorSelectNextWord" $ do
    it "produces valid items" $ producesValidsOnValids textCursorSelectNextWord
    it "is a movement" $ isMovement textCursorSelectNextWord
    it "works for this example" $
      textCursorSelectNextWord (buildTestTextCursor "" "hello") `shouldBe` buildTestTextCursor "hello" ""
    it "works for this example" $
      textCursorSelectNextWord (buildTestTextCursor "hell" "o world") `shouldBe` buildTestTextCursor "hello " "world"
    it "works for this example" $
      textCursorSelectNextWord (buildTestTextCursor "hello" " world") `shouldBe` buildTestTextCursor "hello " "world"
    it "works for this example" $
      textCursorSelectNextWord (buildTestTextCursor "hello " "") `shouldBe` buildTestTextCursor "hello " ""
    it "goes to the end of the cursor" $
      textCursorSelectNextWord (buildTestTextCursor "a\v" "b") `shouldBe` buildTestTextCursor "a\vb" ""
    it "chooses the next word correctly" $
      textCursorSelectNextWord (buildTestTextCursor "a" " b c") `shouldBe` buildTestTextCursor "a " "b c"
  describe "textCursorSelectPrevWord" $ do
    it "produces valid items" $ producesValidsOnValids textCursorSelectPrevWord
    it "is a movement" $ isMovement textCursorSelectPrevWord
    it "works for this example" $
      textCursorSelectPrevWord (buildTestTextCursor "hello" "") `shouldBe` buildTestTextCursor "" "hello"
    it "works for this example" $
      textCursorSelectPrevWord (buildTestTextCursor "hello w" "orld") `shouldBe` buildTestTextCursor "hello" " world"
    it "works for this example" $
      textCursorSelectPrevWord (buildTestTextCursor "hello " "world") `shouldBe` buildTestTextCursor "hello" " world"
    it "works for this example" $
      textCursorSelectPrevWord (buildTestTextCursor " h" "ello") `shouldBe` buildTestTextCursor "" " hello"
    it "goes to the beginning of the cursor" $
      textCursorSelectPrevWord (buildTestTextCursor "a" "\vb") `shouldBe` buildTestTextCursor "" "a\vb"
    it "chooses the previous word correctly" $
      textCursorSelectPrevWord (buildTestTextCursor "a b" " c") `shouldBe` buildTestTextCursor "a" " b c"
  describe "textCursorSplit" $ do
    it "produces valids" $ producesValidsOnValids textCursorSplit
    it "produces two list cursors that rebuild to the rebuilding of the original"
      $ forAllValid
      $ \lc ->
        let (lc1, lc2) = textCursorSplit lc
         in (rebuildTextCursor lc1 <> rebuildTextCursor lc2) `shouldBe` rebuildTextCursor lc
  describe "textCursorCombine" $ do
    it "produces valids" $ producesValidsOnValids2 textCursorCombine
    it "produces a list that rebuilds to the rebuilding of the original two cursors"
      $ forAllValid
      $ \lc1 ->
        forAllValid $ \lc2 ->
          let lc = textCursorCombine lc1 lc2
           in rebuildTextCursor lc `shouldBe` (rebuildTextCursor lc1 <> rebuildTextCursor lc2)

isMovementM :: (TextCursor -> Maybe TextCursor) -> Property
isMovementM func =
  forAllValid $ \tc ->
    case func tc of
      Nothing -> pure () -- Fine
      Just tc' ->
        let t = rebuildTextCursor tc
            t' = rebuildTextCursor tc'
         in unless (t == t')
              $ expectationFailure
              $ unlines
                [ "Cursor before:\n" ++ show tc,
                  "Text before:  \n" ++ show t,
                  "Cursor after: \n" ++ show tc',
                  "Text after:   \n" ++ show t'
                ]

isMovement :: (TextCursor -> TextCursor) -> Property
isMovement func =
  forAllValid $ \lec -> rebuildTextCursor lec `shouldBe` rebuildTextCursor (func lec)

isRemove :: (TextCursor -> Maybe (DeleteOrUpdate TextCursor)) -> Spec
isRemove func = do
  it "preserves everything after the cursor"
    $ forAllValid
    $ \tc -> case func tc of
               Just (Updated tc') -> textCursorNext tc' `shouldBe` textCursorNext tc
               _ -> pure ()
  it "turns everything before the cursor into a prefix"
    $ forAllValid
    $ \tc -> case func tc of
               Just (Updated tc') -> textCursorPrev tc' `shouldSatisfy` (flip isSuffixOf $ textCursorPrev tc)
               _ -> pure ()

isDelete :: (TextCursor -> Maybe (DeleteOrUpdate TextCursor)) -> Spec
isDelete func = do
  it "preserves everything before the cursor"
    $ forAllValid
    $ \tc -> case func tc of
               Just (Updated tc') -> textCursorPrev tc' `shouldBe` textCursorPrev tc
               _ -> pure ()
  it "turns everything after the cursor into a prefix"
    $ forAllValid
    $ \tc -> case func tc of
               Just (Updated tc') -> textCursorNext tc' `shouldSatisfy` (flip isSuffixOf $ textCursorNext tc)
               _ -> pure ()

isIdempotentForSentence :: (TextCursor -> TextCursor) -> Property
isIdempotentForSentence f =
  checkCoverage $ forAllShrink textCursorSentenceGen shrinkSentence $ \tc ->
    let txt = rebuildTextCursor tc
        numChars = T.length txt
        numSpaces = T.length . T.filter isSpace $ txt
     in cover 50 (numSpaces >= 1 && numChars > 2) "non trivial" $ f (f tc) `shouldBe` f tc

buildTestTextCursor :: Text -> Text -> TextCursor
buildTestTextCursor befores afters = TextCursor {textCursorList = ListCursor {listCursorPrev = T.unpack . T.reverse $ befores, listCursorNext = T.unpack afters}}

textCursorNext :: TextCursor -> String
textCursorNext = listCursorNext . textCursorList

textCursorPrev :: TextCursor -> String
textCursorPrev = listCursorPrev . textCursorList

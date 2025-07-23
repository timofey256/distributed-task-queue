{-# LANGUAGE DeriveGeneric, OverloadedStrings #-}
module Examples.Payloads where

import GHC.Generics     (Generic)
import Data.Aeson       (ToJSON, FromJSON)
import Data.Proxy       (Proxy(..))
import Data.Text        (Text, pack, reverse)
import Distributed.TaskQueue.Core (Payload(..))
import           Data.Char (isSpace)

-- Note: handlers themselves are defined with the registy. See `app/MainSend.hs`

--------------------------------------------------------------------------------
-- SumArray --------------------------------------------------------------------
newtype SumArray = SumArray [Int]
  deriving (Show, Generic)

instance ToJSON   SumArray
instance FromJSON SumArray
instance Payload  SumArray where
  taskName _ = "sum-array"

--------------------------------------------------------------------------------
-- ReverseText -----------------------------------------------------------------
newtype ReverseText = ReverseText Text
  deriving (Show, Generic)

instance ToJSON   ReverseText
instance FromJSON ReverseText
instance Payload  ReverseText where
  taskName _ = "reverse-text"

--------------------------------------------------------------------------------
-- Matrix multiplication -------------------------------------------------------
type Matrix = [[Int]]

data MatMul = MatMul
  { mA :: Matrix
  , mB :: Matrix
  }
  deriving (Show, Generic)

instance ToJSON   MatMul
instance FromJSON MatMul
instance Payload  MatMul where
  taskName _ = "mat-mul"

matMul :: Matrix -> Matrix -> Matrix
matMul a b =
  let bt = transpose b
  in [[ sum $ zipWith (*) row col | col <- bt ] | row <- a]

transpose :: Matrix -> Matrix
transpose ([]:_) = []
transpose x      = map head x : transpose (map tail x)

-- helper for matmul in MainSend.hs
-- TODO: move somewhere else
gatherRows :: IO [[Int]]
gatherRows = do
  l <- getLine
  if all isSpace l          -- treat blank/whitespace as terminator
     then pure []
     else do
       let row  = map read (words l)   -- numbers separated by space
       rest <- gatherRows
       pure (row : rest)
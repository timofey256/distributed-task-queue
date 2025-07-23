{-# LANGUAGE DeriveGeneric, OverloadedStrings #-}
module Examples.Payloads where

import GHC.Generics     (Generic)
import Data.Aeson       (ToJSON, FromJSON)
import Data.Proxy       (Proxy(..))
import Data.Text        (Text, pack, reverse)
import Distributed.TaskQueue.Core (Payload(..))

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
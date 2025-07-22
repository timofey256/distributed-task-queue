{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE OverloadedStrings #-}

module Domain where

import Data.Aeson (FromJSON, ToJSON)
import Data.Text  (Text)
import GHC.Generics (Generic)
import qualified Data.Text as T

data TaskType = SumArray | ReverseString
  deriving (Show, Eq, Generic)

instance ToJSON TaskType
instance FromJSON TaskType

data Task = Task
  { taskId   :: T.Text
  , taskType :: TaskType
  , payload  :: T.Text  -- serialized
  } deriving (Show, Generic)

instance ToJSON Task
instance FromJSON Task

data Result = Result
  { resultTaskId :: T.Text
  , resultValue  :: T.Text
  } deriving (Show, Generic)

instance ToJSON Result
instance FromJSON Result

data Config = Config
  { url        :: Text
  , topic_name :: Text
  , timeout    :: Int
  , group_id   :: Text
  } deriving Show
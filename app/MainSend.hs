{-# LANGUAGE OverloadedStrings #-}
module Main where

import Data.Yaml  (decodeFileThrow)
import Data.Aeson (FromJSON(..), withObject, (.:))
import Domain
import Server (runProducerExample)

instance FromJSON Config where
  parseJSON = withObject "Config" $ \v ->
    Config <$> v .: "url"
           <*> v .: "topic_name"
           <*> v .: "timeout"
           <*> v .: "group_id"

main :: IO ()
main = do
  cfg <- decodeFileThrow "data/config.yaml"
  runProducerExample cfg
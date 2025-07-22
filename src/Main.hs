{-# LANGUAGE OverloadedStrings #-}

module Main where

import Data.Yaml  (decodeFileThrow)                     -- only the loader here
import Data.Aeson (FromJSON(..), withObject, (.:))      -- bring the class *and* its methods

import Domain
import Server
import Worker

instance FromJSON Config where
  parseJSON = withObject "Config" $ \v ->
    Config <$> v .: "url"
           <*> v .: "topic_name"
           <*> v .: "timeout"
           <*> v .: "group_id"

main :: IO ()
main = do
  cfg <- decodeFileThrow "data/config.yaml"   -- or use getDataFileName if installed
  print (cfg :: Config)

  putStrLn "Running producer example..."
  runProducerExample cfg

  putStrLn "Running consumer example..."
  runConsumerExample

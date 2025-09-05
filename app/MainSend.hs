{-# LANGUAGE OverloadedStrings #-}
module Main where

import           Data.Yaml                     (decodeFileThrow)
import           Data.Aeson                    (FromJSON(..), withObject, (.:))
import           Kafka.Producer                ( newProducer, closeProducer
                                               , ProducerProperties, brokersList
                                               , sendTimeout, Timeout(..)
                                               , TopicName(..), BrokerAddress(..) )
import           Domain                        (Config(..))
import           Examples.Payloads
import           Data.Text                     (pack)
import           Distributed.TaskQueue.Core    (enqueue)
import           System.IO                     (hFlush, stdout)

-- Parse Config from YAML
instance FromJSON Config where
  parseJSON = withObject "Config" $ \v ->
    Config <$> v .: "url"
           <*> v .: "topic_name"
           <*> v .: "timeout"
           <*> v .: "group_id"

-- Build Kafka producer properties from config
producerProps :: Config -> ProducerProperties
producerProps cfg =
     brokersList [BrokerAddress (url cfg)]
  <> sendTimeout (Timeout (timeout cfg))

main :: IO ()
main = do
  cfg <- decodeFileThrow "data/config.yaml"

  eProd <- newProducer (producerProps cfg)
  case eProd of
    Left err  -> print err                             -- couldn’t connect
    Right prod -> do
      putStrLn "Send 's' for SumArray or 'r' for ReverseText, empty line to quit."

      let topic = TopicName (topic_name cfg)

          -- REPL loop for interactive commands
          loop = do
            putStr "> " >> hFlush stdout
            cmd <- getLine
            case cmd of
              "" -> pure ()
              "s" -> do
                putStrLn "Give numbers separated by space:"
                nums <- fmap (map read . words) getLine
                _ <- enqueue prod topic (SumArray nums)
                putStrLn "enqueued."
                loop
              "r" -> do
                putStrLn "Give text:"
                txt <- getLine
                _ <- enqueue prod topic (ReverseText (pack txt))
                putStrLn "enqueued."
                loop
              "m" -> do
                putStrLn "Enter first matrix rows (numbers separated by space), blank line to finish:"
                aRows <- gatherRows
                putStrLn "Enter second matrix rows:"
                bRows <- gatherRows
                _ <- enqueue prod topic (MatMul aRows bRows)
                putStrLn "mat-mul enqueued."
                loop
              _   -> putStrLn "unknown command" >> loop

      loop
      closeProducer prod

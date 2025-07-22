{-# LANGUAGE OverloadedStrings #-}

module Distributed.TaskQueue.Worker
  ( runWorkers
  , defaultConsumerProps
  , defaultSub
  ) where

import           Control.Exception             (bracket)
import           Control.Monad                  (forever)
import qualified Data.ByteString                as BS
import qualified Data.ByteString.Lazy           as BL
import           Data.Text                      (Text)
import           Kafka.Consumer
import           Distributed.TaskQueue.Registry (HandlerRegistry, lookupHandler)
import           Distributed.TaskQueue.Core    (decodeEnvelope)


-- Users will typically override at least groupId / brokersList.
defaultConsumerProps :: ConsumerProperties
defaultConsumerProps =
       brokersList ["localhost:9092"]
    <> groupId "dtq-worker"
    <> noAutoCommit
    <> logLevel KafkaLogInfo

defaultSub :: Text -> Subscription          -- ^ topic name
defaultSub topic =
       topics [TopicName topic]
    <> offsetReset Earliest

-- | Poll in a tight loop, dispatching each envelope to its handler.
runWorkers
  :: HandlerRegistry
  -> ConsumerProperties
  -> Subscription
  -> IO ()
runWorkers registry props sub = do
  res <- bracket mkConsumer clConsumer runHandler
  either print (const (pure ())) res
 where
  mkConsumer = newConsumer props sub
  clConsumer (Left err) = return (Left err)
  clConsumer (Right kc) = maybe (Right ()) Left <$> closeConsumer kc
  runHandler (Left err) = return (Left err)
  runHandler (Right kc) = forever (loop kc) >> pure (Right ())

  loop kc = do
    eRec <- pollMessage kc (Timeout 1000)
    case eRec of
      Left _err        -> pure ()                          -- logging omitted
      Right record     ->
        case crValue record of
          Nothing   -> pure ()                             -- ignore tombstone
          Just bs -> do
            handle bs
            _ <- commitAllOffsets OffsetCommit kc
            pure ()

  handle :: BS.ByteString -> IO ()
  handle bs = case decodeEnvelope (BL.fromStrict bs) of
    Nothing            -> putStrLn "invalid envelope"
    Just (_, name, v)  ->
      case lookupHandler name registry of
        Nothing   -> putStrLn $ "no handler for: " ++ show name
        Just act  -> act v
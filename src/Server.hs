{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE LambdaCase #-}

module Server where

import Control.Concurrent.MVar (newEmptyMVar, putMVar, takeMVar)
import Control.Exception       (bracket)
import Control.Monad           (forM_)
import Control.Monad.IO.Class  (MonadIO(..))
import Data.ByteString         (ByteString)
import Data.ByteString.Char8   (pack)
import Kafka.Consumer          (Offset)
import Kafka.Producer
import Data.Text               (Text)

import Domain
import Data.Aeson (encode)
import qualified Data.Text as T
import qualified Data.Text.Encoding as TE
import qualified Data.UUID as UUID
import qualified Data.UUID.V4 as UUIDv4
import qualified Data.ByteString.Lazy as BL

-- Global producer properties
producerProps :: Text -> Int -> ProducerProperties
producerProps url timeout =
  brokersList [BrokerAddress url]
  <> sendTimeout (Timeout timeout)
  <> setCallback (deliveryCallback print)
  <> logLevel KafkaLogDebug

-- Topic to send messages to
targetTopic :: TopicName
targetTopic = "kafka-client-example-topic"

mkMessage :: TopicName -> Maybe ByteString -> Maybe ByteString -> ProducerRecord
mkMessage targetTopic k v = ProducerRecord
                  { prTopic = targetTopic
                  , prPartition = UnassignedPartition
                  , prKey = k
                  , prValue = v
                  , prHeaders = mempty
                  }

-- Run an example
runProducerExample :: Config -> IO ()
runProducerExample config =
    bracket mkProducer clProducer runHandler >>= print
    where
      producer_url = url config
      timeout_value = timeout config
      topic = TopicName (topic_name config)
      mkProducer = newProducer (producerProps producer_url timeout_value)
      clProducer (Left _)     = return ()
      clProducer (Right prod) = closeProducer prod
      runHandler (Left err)   = return $ Left err
      runHandler (Right prod) = sendMessages topic prod

sendMessages :: TopicName -> KafkaProducer -> IO (Either KafkaError ())
sendMessages topic prod = do
  putStrLn "Producer is ready, send your messages!"

  putStrLn "Sending first sum array message..."
  createAndSendSumTask prod topic [1,2,3,4,5]

  putStrLn "First message:"
  msg1 <- getLine

  err1 <- produceMessage prod (mkMessage topic (Just "zero") (Just $ pack msg1))
  forM_ err1 print

  putStrLn "One more time!"
  msg2 <- getLine

  err2 <- produceMessage prod (mkMessage topic (Just "key") (Just $ pack msg2))
  forM_ err2 print

  putStrLn "And the last one..."
  msg3 <- getLine
  err3 <- produceMessage prod (mkMessage topic (Just "key3") (Just $ pack msg3))

  err4 <- produceMessage prod ((mkMessage topic (Just "key4") (Just $ pack msg3)) { prHeaders = headersFromList [("fancy", "header")]})

  -- forM_ errs (print . snd)

  putStrLn "Thank you."
  return $ Right ()

sendMessageSync :: MonadIO m
                => KafkaProducer
                -> ProducerRecord
                -> m (Either KafkaError Offset)
sendMessageSync producer record = liftIO $ do
  -- Create an empty MVar:
  var <- newEmptyMVar

  -- Produce the message and use the callback to put the delivery report in the
  -- MVar:
  res <- produceMessage' producer record (putMVar var)

  case res of
    Left (ImmediateError err) ->
      pure (Left err)
    Right () -> do
      -- Flush producer queue to make sure you don't get stuck waiting for the
      -- message to send:
      flushProducer producer

      -- Wait for the message's delivery report and map accordingly:
      takeMVar var >>= return . \case
        DeliverySuccess _ offset -> Right offset
        DeliveryFailure _ err    -> Left err
        NoMessageError err       -> Left err

sendTask :: KafkaProducer -> TopicName -> Task -> IO ()
sendTask prod topic task = do
  let msg = mkMessage topic (Just $ TE.encodeUtf8 $ taskId task) (Just $ BL.toStrict (encode task))
  produceMessage prod msg >>= mapM_ print

createAndSendSumTask :: KafkaProducer -> TopicName -> [Int] -> IO ()
createAndSendSumTask prod topic numbers = do
  uuid <- UUID.toText <$> UUIDv4.nextRandom
  let task = Task uuid SumArray (T.pack $ show numbers)
  sendTask prod topic task

createAndSendReverseTask :: KafkaProducer -> TopicName -> String -> IO ()
createAndSendReverseTask prod topic str = do
  uuid <- UUID.toText <$> UUIDv4.nextRandom
  let task = Task uuid ReverseString (T.pack str)
  sendTask prod topic task

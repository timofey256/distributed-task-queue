{-# LANGUAGE ExistentialQuantification #-}
{-# LANGUAGE DeriveAnyClass            #-}
{-# LANGUAGE DeriveGeneric             #-}
{-# LANGUAGE OverloadedStrings         #-}
{-# LANGUAGE ScopedTypeVariables       #-}
{-# LANGUAGE TypeApplications          #-}

module Distributed.TaskQueue.Core
  ( Payload(..)
  , TaskEnvelope(..)
  , encodeEnvelope
  , decodeEnvelope
  , enqueue
  ) where

import           Data.Aeson            ( Value, decode, encode
                                       , withObject, (.:)
                                       , object, (.=)
                                       , ToJSON(..), FromJSON(..) )
import qualified Data.Aeson.Types     as AT (parseMaybe)
import qualified Data.ByteString.Lazy as BL
import           Data.Proxy           (Proxy(..))
import           Data.Text            (Text)
import qualified Data.Text.Encoding   as TE
import           Data.Typeable        (Typeable, cast)
import           GHC.Generics         (Generic)
import           Kafka.Producer
import           Data.UUID            (UUID)
import qualified Data.UUID.V4         as UUIDv4

-- Typeclass for all payloads that can be enqueued
--   * Must be serializable (ToJSON, FromJSON)
--   * Must be typeable (runtime reflection)
class (ToJSON p, FromJSON p, Typeable p) => Payload p where
  taskName :: Proxy p -> Text

-- Universal task wrapper that adds a UUID to any Payload
data TaskEnvelope = forall p. Payload p => TaskEnvelope
  { envId      :: UUID
  , envPayload :: p
  }

-- Encode envelope into JSON object
-- { "id": ..., "name": ..., "body": ... }
instance ToJSON TaskEnvelope where
  toJSON (TaskEnvelope u (payload :: p)) =
    object [ "id"   .= u
           , "name" .= taskName (Proxy :: Proxy p)
           , "body" .= toJSON payload
           ]

encodeEnvelope :: TaskEnvelope -> BL.ByteString
encodeEnvelope = encode

-- Decode envelope into (UUID, task name, JSON body)
-- Body is left as raw JSON Value so we can dispatch dynamically.
decodeEnvelope :: BL.ByteString -> Maybe (UUID, Text, Value)
decodeEnvelope bs =
  decode bs >>= AT.parseMaybe
                 (withObject "TaskEnvelope" $ \o ->
                    (,,) <$> o .: "id"
                         <*> o .: "name"
                         <*> o .: "body")

-- Enqueue a payload into Kafka.
-- Steps:
-- 1. Generate UUID
-- 2. Wrap in TaskEnvelope
-- 3. Serialize to JSON
-- 4. Send as Kafka message with key = task name
-- 5. Return UUID
enqueue
  :: forall p. Payload p
  => KafkaProducer
  -> TopicName
  -> p                    -- ^ strongly‑typed payload
  -> IO UUID              
enqueue prod topic p = do
  uuid <- UUIDv4.nextRandom
  let env   = TaskEnvelope uuid p
      bytes = BL.toStrict (encodeEnvelope env)
      key   = TE.encodeUtf8 (taskName (Proxy :: Proxy p))
      msg   = ProducerRecord
                { prTopic     = topic
                , prPartition = UnassignedPartition
                , prKey       = Just key
                , prValue     = Just bytes
                , prHeaders   = mempty
                }
  _ <- produceMessage prod msg
  pure uuid

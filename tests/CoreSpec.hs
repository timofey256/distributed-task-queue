{-# LANGUAGE OverloadedStrings #-}
module CoreSpec (spec) where

import Test.Hspec
import Data.Aeson (toJSON)
import qualified Data.Aeson as A
import qualified Data.ByteString.Lazy as BL
import Data.UUID (UUID)
import Distributed.TaskQueue.Core
import Examples.Payloads (SumArray(..), ReverseText(..))

spec :: Spec
spec = do
  describe "TaskEnvelope encoding/decoding" $ do
    it "roundtrips SumArray" $ do
      let env = TaskEnvelope (read "123e4567-e89b-12d3-a456-426614174000")
                             (SumArray [1,2,3])
          bs  = encodeEnvelope env
      decodeEnvelope bs `shouldBe`
        Just (read "123e4567-e89b-12d3-a456-426614174000",
              "sum-array",
              toJSON (SumArray [1,2,3]))

    it "roundtrips ReverseText" $ do
      let env = TaskEnvelope (read "123e4567-e89b-12d3-a456-426614174111")
                             (ReverseText "hello")
          bs  = encodeEnvelope env
      decodeEnvelope bs `shouldBe`
        Just (read "123e4567-e89b-12d3-a456-426614174111",
              "reverse-text",
              toJSON (ReverseText "hello"))

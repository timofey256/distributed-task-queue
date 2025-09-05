{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TypeApplications  #-}
module RegistrySpec (spec) where

import Test.Hspec
import Data.Aeson (toJSON)
import Data.Maybe (isJust)
import Distributed.TaskQueue.Registry
import Examples.Payloads (SumArray(..))

spec :: Spec
spec = do
  describe "HandlerRegistry" $ do
    it "registers and finds handler" $ do
      let reg = register @SumArray (\(SumArray xs) -> print (sum xs)) emptyRegistry
          ref = lookupHandler "sum-array" reg
      isJust ref `shouldBe` True

    it "runs handler successfully" $ do
      let reg = register @SumArray (\(SumArray xs) -> xs `shouldBe` [1,2]) emptyRegistry
      case lookupHandler "sum-array" reg of
        Nothing  -> expectationFailure "handler not found"
        Just act -> act (toJSON (SumArray [1,2]))

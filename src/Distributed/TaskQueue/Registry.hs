{-# LANGUAGE RankNTypes #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TypeApplications #-}

module Distributed.TaskQueue.Registry
  ( HandlerRegistry
  , emptyRegistry
  , register
  , lookupHandler
  ) where

import           Data.Aeson            (Value, fromJSON, Result(..))
import qualified Data.HashMap.Strict   as HM
import           Data.Proxy            (Proxy(..))
import           Data.Text             (Text)

import           Distributed.TaskQueue.Core (Payload(..))

newtype HandlerRegistry =
        HR (HM.HashMap Text (Value -> IO ()))

emptyRegistry :: HandlerRegistry
emptyRegistry = HR HM.empty

register   :: forall p. Payload p
           => (p -> IO ())     -- ^ handler
           -> HandlerRegistry
           -> HandlerRegistry
register f (HR m) = HR $ HM.insert (taskName (Proxy @p)) go m
  where
    go v = case fromJSON v of
             Success (payload :: p) -> f payload
             Error err              -> putStrLn ("decode error: " ++ err)

lookupHandler :: Text -> HandlerRegistry -> Maybe (Value -> IO ())
lookupHandler name (HR m) = HM.lookup name m

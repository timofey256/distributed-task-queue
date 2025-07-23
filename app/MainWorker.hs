{-# LANGUAGE OverloadedStrings, TypeApplications #-}
module Main where

import           Distributed.TaskQueue.Registry (emptyRegistry, register)
import           Distributed.TaskQueue.Worker   (runWorkers, defaultConsumerProps, defaultSub)
import           Examples.Payloads
import           Data.Text                      (reverse, unpack)

-- handlers ---------------------------------------------------
sumHandler :: SumArray -> IO ()
sumHandler (SumArray xs) = print (sum xs)

reverseHandler :: ReverseText -> IO ()
reverseHandler (ReverseText t) = putStrLn (unpack (Data.Text.reverse t))

matMulHandler :: MatMul -> IO ()
matMulHandler (MatMul a b) = print (matMul a b)

registry = register @ReverseText reverseHandler
         $ register @SumArray    sumHandler
         $ register @MatMul      matMulHandler
         $ emptyRegistry

main :: IO ()
main = runWorkers registry defaultConsumerProps (defaultSub "kafka-client-example-topic")
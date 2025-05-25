module Main where

import Server
import Worker

main :: IO ()
main = do
  putStrLn "Running producer example..."
  runProducerExample

  putStrLn "Running consumer example..."
  runConsumerExample

  putStrLn "Ok."

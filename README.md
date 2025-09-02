# Distributed Task Queue

## Overview

This a library for building distributed task processing systems on top of Kafka.
It provides a simple way to:

* **Define your own tasks** (any serializable Haskell type).
* **Enqueue tasks** into Kafka.
* **Register workers** to process tasks.

There are built-in examples (`SumArray`, `ReverseText`) but you are not restricted to them. You can define tasks yourself and plug them into the system.

---

## Typical Use Cases

* Background job execution (email sending, report generation).
* Parallel data processing (matrix multiplication, map-reduce style tasks).
* Real-time task scheduling (streaming pipelines).
---

## Installation

Add the dependency to your `.cabal` file:

```cabal
build-depends:
    distributed-task-queue >= 0.0.1
```

Or install locally:

```bash
cabal install distributed-task-queue
```

Kafka must be running locally (default: `localhost:9092`) or on your cluster. See a [short guide](./docs/how-to-kafka.md) on how to set it up.

---

## Quick Start

### 1. Define a task

```haskell
{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE OverloadedStrings #-}

import GHC.Generics
import Data.Aeson (ToJSON, FromJSON)
import Data.Text (Text)
import Distributed.TaskQueue.Core (Payload(..))

-- Define your own task
newtype Uppercase = Uppercase Text
  deriving (Show, Generic)

instance ToJSON   Uppercase
instance FromJSON Uppercase
instance Payload  Uppercase where
  taskName _ = "uppercase"
```

---

### 2. Create a producer to enqueue tasks

```haskell
import Distributed.TaskQueue.Core (enqueue)
import Kafka.Producer (newProducer, TopicName(..))
import Data.Text (pack)

main = do
  Right producer <- newProducer []   -- configure Kafka broker
  uuid <- enqueue producer (TopicName "tasks") (Uppercase "hello world")
  print ("Enqueued task with ID: " ++ show uuid)
```

---

### 3. Register a worker to handle tasks

```haskell
import Distributed.TaskQueue.Registry
import Distributed.TaskQueue.Worker
import Data.Text (unpack, toUpper)

uppercaseHandler :: Uppercase -> IO ()
uppercaseHandler (Uppercase t) = putStrLn (map toUpper (unpack t))

registry =
    register @Uppercase uppercaseHandler
  $ emptyRegistry

main = runWorkers registry defaultConsumerProps (defaultSub "tasks")
```

---

## Very quick start

If you just want to see a demo, you can run ready-made executables:

* **Producer CLI** (`dtq-send`)
  If supports basic tasks - `SumArray`, or `ReverseText` interactively.

* **Worker CLI** (`dtq-worker`)
  Runs worker processes with handlers for the example payloads.

Run them in separate terminals:

```bash
cabal run dtq-worker
cabal run dtq-send
```

---

## Configuration

Configuration is read from `data/config.yaml`:

```yaml
url: localhost:9092
topic_name: kafka-client-example-topic
timeout: 10000
group_id: consumer_example_group
```

* `url` – Kafka broker address
* `topic_name` – Kafka topic for tasks
* `timeout` – Producer send timeout in ms
* `group_id` – Consumer group id

---

## Developer documentation

You can find developer documentation [here](./docs/developer-documentation.md).

# Developer Documentation

## Design Overview

The system is split into 3 layers:

1. **Core (serialization & enqueueing)**

   * Defines the `Payload` typeclass.
   * Encodes tasks into envelopes with UUIDs.
   * Pushes messages to Kafka.

2. **Registry (handler binding)**

   * Maps task names to handlers.
   * Supports safe registration of multiple task types.

3. **Worker (execution loop)**

   * Kafka consumer loop.
   * Decodes messages and dispatches to registered handlers.

---

## Code Organization

```
src/
    Domain.hs - Basic types (`Task`, `Result`, `Config`).

    Examples/
        Payloads.hs - Example payloads (`SumArray`, `ReverseText`, `MatMul`).

    Distributed/
        TaskQueue/
            Core.hs - `Payload` class, `TaskEnvelope` (wrapper with UUID and payload), `enqueue` (push a typed task to Kafka).
            Registry.hs - register (bind a payload type to its handler), lookupHandler (resolve handlers dynamically).
            Worker.hs - runWorkers (main loop for polling Kafka), `defaultConsumerProps`, `defaultSub` (preconfigured Kafka consumer options).

app/
    MainSend.hs - interactive producer CLI.
    MainWorker.hs - worker CLI with example handlers.
```

---

## Key Functions

* **`enqueue`**

  ```haskell
  enqueue :: Payload p => KafkaProducer -> TopicName -> p -> IO UUID
  ```

  Serializes payload, wraps it in an envelope, and sends it to Kafka.

* **`register`**

  ```haskell
  register :: Payload p => (p -> IO ()) -> HandlerRegistry -> HandlerRegistry
  ```

  Registers a handler for a task type.

* **`runWorkers`**

  ```haskell
  runWorkers :: HandlerRegistry -> ConsumerProperties -> Subscription -> IO ()
  ```

  Runs the worker loop, dispatching tasks to registered handlers.

---

## Extensibility

To add new functionality:

1. Define a new `Payload` type.
2. Write a handler `(p -> IO ())`.
3. Register the handler in the worker’s registry.
4. Enqueue tasks of this type from the producer.

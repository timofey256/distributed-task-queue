{-# LANGUAGE ExistentialQuantification #-}

module SharedDomain.Core where

import Data.Map
import Data.Time.Clock (UTCTime)
import Data.Typeable (Typeable)
import Data.ByteString (ByteString)
import Control.Concurrent
import Control.Concurrent.STM

type TaskId = String

data TaskResult = Success | Failure String

data TaskType = TODOSomeType1 | TODOSomeType2

data Priority = High | Moderate | Low

class (Typeable a, Show a) => Task a where
    taskId :: a -> String

    serialize :: a -> ByteString
    deserialize :: ByteString -> Maybe a

    priority :: a -> Priority

    maxRetries :: a -> Int
    timeoutInSeconds :: a -> Int 

    memoryRequiredInMB :: a -> Maybe Int
    cpuRequired :: a -> Maybe Int

-- existential type
-- https://wiki.haskell.org/Existential_type
-- define it so we can use it as an "interface" for tasks in TaskQueue
data AnyTask = forall a. Task a => AnyTask a 

data TaskQueue = TaskQueue
    {
        pendingTasks   :: TQueue AnyTask,
        runningTasks   :: TVar (Map TaskId (AnyTask, WorkerId)),
        completedTasks :: TVar (Map TaskId TaskResult)
    }

type WorkerId = String

data WorkerInfo = WorkerInfo
    {
        workerId :: WorkerId,
        workerName :: String
    }

data WorkerRegistry = WorkerRegistry
    {
        availableWorkers :: TVar (Map WorkerId WorkerInfo),
        busyWorkers      :: TVar (Map WorkerId (WorkerInfo, Int))
    }


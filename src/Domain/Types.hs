module Domain.Types where

import Data.Map
import Control.Concurrent.STM
import Control.Concurrent

type TaskId = string

data TaskType = TODOSomeType1 | TODOSomeType2

data Priority = High | Moderate | Low

data TaskWithMetadata = TaskWithMetadata
    {
        taskId :: TaskId, 
        taskContent :: String, 
        taskType :: TaskType,
        priority :: Priority,
        dependencies :: [TaskId],
        attempts :: Int,
        submittedAt :: UTCTime
    }

data TaskQueue = TaskQueue
    {
        pendingTasks   :: TQueue TaskWithMetadata,
        runningTasks   :: TVar (Map TaskId (TaskWithMetadata, WorkerId)),
        completedTasks :: TVar (Map TaskId TaskResult)
    }

type WorkerId = string

data WorkerRegistry = WorkerRegistry
    {
        availableWorkers :: TVar (Map WorkerId WorkerInfo),
        busyWorkers      :: TVar (Map WorkerId (WorkerInfo, Int))
    }


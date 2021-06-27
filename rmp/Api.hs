{-# LANGUAGE DataKinds     #-}
{-# LANGUAGE TypeOperators #-}

module Api where

import           Pull
import           Servant

type PullsApi =
  "pulls" :> Get '[JSON] [Pull] :<|>
  "pulls" :> Capture "pullId" Integer :> Get '[JSON] Pull

pullsApi :: Proxy PullsApi
pullsApi = Proxy

server :: Server PullsApi
server =
  getPulls :<|>
  getPullById pulls

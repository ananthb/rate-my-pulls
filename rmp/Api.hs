{- Copyright 2020, Ananth Bhaskararaman

   This file is part of Rate My Pulls.

   Rate My Pulls is free software: you can redistribute it and/or modify
   it under the terms of the GNU Affero General Public License as
   published by the Free Software Foundation, version 3 of the License.

   Rate My Pulls is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
   GNU Affero General Public License for more details.

   You should have received a copy of the GNU Affero General Public
   License along with Rate My Pulls.  If not, see
   <https://www.gnu.org/licenses/>.
-}

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

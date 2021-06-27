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
{-# LANGUAGE DataKinds #-}
{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE TypeOperators #-}

module Main where

import           Data.Aeson
import           GHC.Generics
import           Network.Wai
import           Network.Wai.Handler.Warp
import           Servant
import           System.IO

-- * api

type PullsApi =
  "pulls" :> Get '[JSON] [Pull] :<|>
  "pulls" :> Capture "pullId" Integer :> Get '[JSON] Pull

pullsApi :: Proxy PullsApi
pullsApi = Proxy

-- * app

main :: IO ()
main = do
  let port = 8080
      settings =
        setPort port $
        setBeforeMainLoop (hPutStrLn stderr ("listening on port " ++ show port)) $
        defaultSettings
  runSettings settings =<< mkApp

mkApp :: IO Application
mkApp = return $ serve pullsApi server

server :: Server PullsApi
server =
  getPulls :<|>
  getPullById

getPulls :: Handler [Pull]
getPulls = return [examplePull]

getPullById :: Integer -> Handler Pull
getPullById = \ case
  0 -> return examplePull
  _ -> throwError err404

examplePull :: Pull
examplePull = Pull 0 "example pull request"

-- * item

data Pull
  = Pull {
    pullId :: Integer,
    pullText :: String
  }
  deriving (Eq, Show, Generic)

instance ToJSON Pull
instance FromJSON Pull

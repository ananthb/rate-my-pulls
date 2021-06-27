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

{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE LambdaCase    #-}

module Pull where

import           Data.Aeson
import           Data.List
import           GHC.Generics
import           Servant

data Pull
  = Pull {
    pullId   :: Integer,
    pullText :: String
  }
  deriving (Eq, Show, Generic)

instance ToJSON Pull
instance FromJSON Pull

getPulls :: Handler [Pull]
getPulls = return pulls

getPullById :: [Pull] -> Integer -> Handler Pull
getPullById ps i =
    case find (\x -> pullId x == i) ps of
      Just p  -> return p
      Nothing -> throwError err404

pulls :: [Pull]
pulls =
  [ Pull 0 "pull 0"
  , Pull 1 "pull 1"
  , Pull 2 "pull 2"
  ]

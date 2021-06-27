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

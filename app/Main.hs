{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE OverloadedRecordDot #-}
{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE DeriveAnyClass #-}

import System.Environment (lookupEnv)

import Control.Concurrent (threadDelay)
import Control.Monad (when, void, guard)
import Control.Monad.IO.Class (MonadIO, liftIO)

import Data.Monoid ((<>))
import Data.Coerce (coerce)
import Data.Word (Word64)
import Data.Yaml (decodeFileEither, FromJSON, ToJSON)
import Data.Text (Text, isInfixOf, pack, unpack)
import Data.Text.IO (putStrLn, writeFile)
import Prelude hiding (putStrLn)

import GHC.Generics (Generic)

import Discord
import Discord.Types
import Discord.Requests

printLn :: MonadIO a => Text -> a ()
printLn = liftIO . putStrLn

showT :: Show a => a -> Text
showT = pack . show

data Config = Config {
  maxHistory :: Int,
  mainGuildId :: Word64,
  mainChannelId :: Word64
} deriving (Show, Generic, FromJSON, ToJSON)

loadConfig :: IO (Maybe Config)
loadConfig = do
  result <- decodeFileEither "config.yaml"
  case result of
    Left err -> return Nothing
    Right conf -> return (Just conf)

main :: IO ()
main = do
  config <- loadConfig
  case config of
    Nothing -> printLn "[conf] config.yaml format error"
    Just conf -> do
      printLn "[conf] Loaded config.yaml"

      findId <- lookupEnv "HCCBOT_ID"
      findToken <- lookupEnv "HCCBOT_TOKEN"

      case (findId, findToken) of
        (Nothing, _) -> printLn "[env] HCCBOT_ID is not set"
        (_, Nothing) -> printLn "[env] HCCBOT_TOKEN is not set"
        (Just botId, Just botToken) -> do
          let self = pack $ "<@" <> botId <> ">"
          result <- runDiscord $ def {
            discordToken = pack botToken,
            discordOnEvent = eebot self conf
          }
          printLn result

eebot :: Text -> Config -> Event -> DiscordHandler ()
eebot self conf event = case event of
  Ready {} -> do
    printLn $ "[start] HCC eebot !!! uwu"
    printLn $ "[guild] " <> showT (mainGuildId conf)
    printLn $ "[channel] " <> showT (mainChannelId conf)

  MessageCreate msg -> when (not $ fromBot msg) $ do
    let clubId = messageGuildId msg
        roomId = messageChannelId msg
        textId = messageId msg
        text = messageContent msg
        user = userName $ messageAuthor msg

    guard (coerce clubId == Just (mainGuildId conf))

    when (self `isInfixOf` text) $ do
      void $ restCall $ CreateReaction (roomId, textId) "fire"

    when (coerce roomId == mainChannelId conf) $ do
      printLn $ "[msg] " <> user <> ": " <> text

fromBot :: Message -> Bool
fromBot = userIsBot . messageAuthor
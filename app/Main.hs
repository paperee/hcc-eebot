{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE OverloadedRecordDot #-}
{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE DeriveAnyClass #-}

import System.Environment (lookupEnv)
import System.IO (hSetEncoding, utf8, stdout, stderr)

import Control.Concurrent (threadDelay)
import Control.Monad (when, void, guard)
import Control.Monad.IO.Class (MonadIO, liftIO)

import Data.Monoid ((<>))
import Data.Yaml (decodeFileEither, FromJSON, ToJSON)
import Data.Text (Text, isInfixOf, pack, unlines)
import Data.Text.IO (putStrLn)
import Data.Text.Encoding (encodeUtf8)
import Data.ByteString (writeFile)

import Prelude hiding (putStrLn, writeFile, unlines)

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
  mainGuildId :: GuildId,
  mainChannelId :: ChannelId
} deriving (Show, Generic, FromJSON, ToJSON)

loadConfig :: IO (Maybe Config)
loadConfig = do
  result <- decodeFileEither "config.yaml"
  case result of
    Left _ -> return Nothing
    Right conf -> return (Just conf)

main :: IO ()
main = do
  hSetEncoding stdout utf8
  hSetEncoding stderr utf8

  config <- loadConfig
  case config of
    Nothing -> printLn "[conf] config.yaml format error"
    Just conf -> do
      printLn "[conf] loaded config.yaml"

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
    printLn $ "[hi] HCC eebot !!! uwu"
    printLn $ "[club] " <> showT (mainGuildId conf)
    printLn $ "[room] " <> showT (mainChannelId conf)
    getHistory (mainChannelId conf) (maxHistory conf)

  MessageCreate msg -> when (not $ fromBot msg) $ do
    let clubId = messageGuildId msg
        roomId = messageChannelId msg
        textId = messageId msg
        text = messageContent msg
        user = userName $ messageAuthor msg

    guard (clubId == Just (mainGuildId conf))

    when (self `isInfixOf` text) $ do
      void $ restCall $ CreateReaction (roomId, textId) "fire"

    when (roomId == mainChannelId conf) $ do
      printLn $ "[msg] " <> user <> ": " <> text

fromBot :: Message -> Bool
fromBot = userIsBot . messageAuthor

getHistory :: ChannelId -> Int -> DiscordHandler ()
getHistory roomId limit = do
  printLn $ "[msgs] start getting " <> showT limit <> " msgs"
  msgs <- nextBatch roomId limit []

  let writeTo = "history.txt"
      content = unlines $ map formatMsg msgs

  liftIO $ writeFile writeTo (encodeUtf8 content)
  printLn $ "[msgs] written " <> showT (length msgs) <> " msgs"

nextBatch :: ChannelId -> Int -> [Message] -> DiscordHandler [Message]
nextBatch _ remaining acc | remaining <= 0 = return (reverse acc)
nextBatch roomId remaining acc = do
  let size = min 100 remaining
      point = case acc of
        [] -> LatestMessages
        ms -> BeforeMessage (messageId $ last ms)

  result <- restCall $ GetChannelMessages roomId (size, point)

  case result of
    Left _ -> return (reverse acc)
    Right new | null new -> return (reverse acc)
    Right new -> nextBatch roomId (remaining - length new) (acc <> new)

formatMsg :: Message -> Text
formatMsg msg = (userName $ messageAuthor msg) <> ": " <> messageContent msg
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE OverloadedRecordDot #-}
{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE DeriveAnyClass #-}

import System.Environment (lookupEnv)

import Control.Concurrent (threadDelay, forkIO)
import Control.Monad (when, void, guard, forever)
import Control.Monad.IO.Class (MonadIO, liftIO)

import GHC.Generics (Generic)
import Data.Yaml (decodeFileEither, FromJSON, ToJSON)
import Data.ByteString (writeFile)
import Data.Monoid ((<>))
import Data.Maybe (mapMaybe)
import Data.Text (Text, isInfixOf, pack, unlines, null)
import Data.Text.IO (putStrLn)
import Data.Text.Encoding (encodeUtf8)

import Prelude hiding (putStrLn, writeFile, unlines, print, null)

import Control.Concurrent.MVar (MVar, newMVar, swapMVar)

import Discord
import Discord.Types
import Discord.Requests

import Groq -- uwu

print :: MonadIO a => Text -> a ()
print = liftIO . putStrLn

ps :: Show a => a -> Text
ps = pack . show

data Config = Config {
  timeInterval :: Int,
  maxHistory :: Int,
  historyPath :: String,
  reportPath :: String,
  promptPath :: String,
  groqModel :: String,
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
  config <- loadConfig
  case config of
    Nothing -> print "[conf] config.yaml format error"
    Just conf -> do
      print "[conf] loaded config.yaml"

      botId <- lookupEnv "HCCBOT_ID"
      botToken <- lookupEnv "HCCBOT_TOKEN"
      apiKey <- lookupEnv "GROQ_API_KEY"

      case (botId, botToken, apiKey) of
        (Nothing, _, _) ->
          print "[env] HCCBOT_ID is not set"

        (_, Nothing, _) ->
          print "[env] HCCBOT_TOKEN is not set"

        (_, _, Nothing) ->
          print "[env] GROQ_API_KEY is not set"

        (Just id_, Just token_, Just key_) -> do
          flag <- newMVar False
          result <- runDiscord $ def {
            discordToken = pack token_,
            discordOnEvent = eebot id_ key_ conf flag
          }
          print result

eebot :: String -> String -> Config -> MVar Bool -> Event -> DiscordHandler ()
eebot id_ key_ conf flag event = case event of
  Ready {} -> do
    let maxHLen = maxHistory conf
        timeInt = timeInterval conf
        filePath = historyPath conf
        mainClub = mainGuildId conf
        mainRoom = mainChannelId conf

    print $ "[hi] HCC eebot !!! uwu"
    print $ "[club] " <> ps (mainClub)
    print $ "[room] " <> ps (mainRoom)

    getHistory mainRoom maxHLen filePath

    void $ liftIO $ forkIO $ forever $ do
      threadDelay (timeInt * 60000000) -- 60s
      void $ swapMVar flag True

  MessageCreate msg -> do
    let maxHLen = maxHistory conf
        filePath = historyPath conf
        mainClub = mainGuildId conf
        mainRoom = mainChannelId conf
        mention = pack $ "<@" <> id_ <> ">"

    signal <- liftIO $ swapMVar flag False
    when signal $ getHistory mainRoom maxHLen filePath

    when (not $ userIsBot (messageAuthor msg)) $ do
      let user = userName $ messageAuthor msg
          text = messageContent msg
          textId = messageId msg
          clubId = messageGuildId msg
          roomId = messageChannelId msg

      guard (clubId == Just (mainClub))

      when (mention `isInfixOf` text) $ do -- test
        void $ restCall $ CreateReaction (roomId, textId) "fire"

      when (roomId == mainRoom && not (null text)) $ do
        print $ "[msg] " <> user <> ": " <> text

  _ -> return ()

formatMsg :: Message -> Maybe Text
formatMsg msg =
  let user = userName $ messageAuthor msg
      text = messageContent msg

  in guard (not $ null text) >> return (user <> ": " <> text)

getHistory :: ChannelId -> Int -> String -> DiscordHandler ()
getHistory roomId limit hPath = do
  print $ "[msgs] start getting " <> ps limit <> " msgs"
  msgs <- nextBatch roomId limit []

  let formatted = mapMaybe formatMsg msgs
      content = unlines $ formatted

  liftIO $ writeFile hPath (encodeUtf8 content)
  print $ "[msgs] written " <> ps (length formatted) <> " msgs"

nextBatch :: ChannelId -> Int -> [Message] -> DiscordHandler [Message]
nextBatch _ rest acc | rest <= 0 = return (reverse acc)
nextBatch roomId rest acc = do
  let size = min 100 rest
      point = case acc of
        [] -> LatestMessages
        ms -> BeforeMessage (messageId $ last ms)

  result <- restCall $ GetChannelMessages roomId (size, point)

  liftIO $ threadDelay 500000 -- 0.5s

  case result of
    Left _ -> return (reverse acc)
    Right new | length new <= 0 -> return (reverse acc)
    Right new -> nextBatch roomId (rest - length new) (acc <> new)
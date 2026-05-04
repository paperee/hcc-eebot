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
import Data.ByteString (readFile, writeFile)
import Data.Monoid ((<>))
import Data.Maybe (mapMaybe)
import Data.Text (Text, isInfixOf, pack, unpack, unlines, null)
import Data.Text.IO (putStrLn)
import Data.Text.Encoding (encodeUtf8, decodeUtf8)

import Prelude hiding (putStrLn, readFile, writeFile, unlines, print, null)

import Control.Concurrent.MVar (MVar, newMVar, swapMVar)

import Discord
import Discord.Types
import Discord.Requests

import Groq (callGroq) -- uwu

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
  loadConfig >>= \config -> case config of
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

          void $ runDiscord $ def {
            discordToken = pack token_,
            discordOnEvent = eebot id_ key_ conf flag
          }

eebot :: String -> String -> Config -> MVar Bool -> Event -> DiscordHandler ()
eebot id_ key_ conf flag event = case event of
  Ready {} -> do
    let mainClub = mainGuildId conf
        mainRoom = mainChannelId conf

    print $ "[join] HCC eebot !!! uwu"
    print $ "[club] " <> ps (mainClub)
    print $ "[room] " <> ps (mainRoom)

    sumHistory mainRoom key_ conf

    let timeInt = timeInterval conf

    void $ liftIO $ forkIO $ forever $ do
      threadDelay (timeInt * 60000000) -- 60s
      void $ swapMVar flag True

  MessageCreate msg -> do
    let mainClub = mainGuildId conf
        mainRoom = mainChannelId conf
        mention = pack $ "<@" <> id_ <> ">"

    signal <- liftIO $ swapMVar flag False
    when signal $ sumHistory mainRoom key_ conf

    when (not $ userIsBot (messageAuthor msg)) $ do
      let user = userName $ messageAuthor msg
          text = messageContent msg
          textId = messageId msg
          clubId = messageGuildId msg
          roomId = messageChannelId msg

      guard (clubId == Just (mainClub))

      when (mention `isInfixOf` text) $ do -- burn
        void $ restCall $ CreateReaction (roomId, textId) "fire"

      when (roomId == mainRoom && not (null text)) $ do
        print $ "[log] " <> user <> ": " <> text -- peek

  _ -> return ()

sumHistory :: ChannelId -> String -> Config -> DiscordHandler ()
sumHistory mainRoom key_ conf = do
  let maxHLen = maxHistory conf
      histPath = historyPath conf
      reptPath = reportPath conf
      pmptPath = promptPath conf

  let mod_ = groqModel conf

  getHistory mainRoom maxHLen histPath >>=
    getReport reptPath pmptPath key_ mod_

getHistory :: ChannelId -> Int -> String -> DiscordHandler Text
getHistory roomId hLen hPath = do
  print $ "[logs] start getting " <> ps hLen <> " msgs"
  msgs <- nextBatch roomId hLen []

  let formatted = mapMaybe formatMsg msgs
      content = unlines $ formatted

  liftIO $ writeFile hPath (encodeUtf8 content)
  print $ "[logs] written " <> ps (length formatted) <> " msgs to " <> pack hPath

  return content

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

formatMsg :: Message -> Maybe Text
formatMsg msg =
  let user = userName $ messageAuthor msg
      text = messageContent msg

  in guard (not $ null text) >> return (user <> ": " <> text)

getReport :: String -> String -> String -> String -> Text -> DiscordHandler ()
getReport rPath pPath key_ mod_ hist = do
  print $ "[logs] start requesting " <> pack mod_
  pmpt <- liftIO $ readFile pPath
  print $ "[logs] loaded " <> pack pPath

  let text = decodeUtf8 pmpt <> "\n\n" <> hist

  content <- liftIO $ callGroq key_ mod_ (unpack text)
  liftIO $ writeFile rPath (encodeUtf8 content)
  print $ "[logs] written to " <> pack rPath
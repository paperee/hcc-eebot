{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE DeriveAnyClass #-}
{-# LANGUAGE RecordWildCards #-}

import System.Environment (lookupEnv)

import Control.Concurrent (threadDelay, forkIO)
import Control.Monad (when, void, guard, forever)
import Control.Monad.IO.Class (MonadIO, liftIO)

import GHC.Generics (Generic)
import Data.Yaml (decodeFileEither, FromJSON, ToJSON)
import Data.ByteString (readFile, writeFile)
import Data.Monoid ((<>))
import Data.Maybe (mapMaybe)
import Data.Text (Text, isInfixOf, pack, unpack, unlines, null, replace)
import Data.Text.IO (putStrLn)
import Data.Text.Encoding (encodeUtf8, decodeUtf8)
import Data.Foldable (traverse_)

import Data.Time (getCurrentTime)
import Data.Time.LocalTime (utcToLocalTime, hoursToTimeZone)
import Data.Time.Format (formatTime, defaultTimeLocale)

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
  headerPath :: String,
  groqModel :: String,
  mainClubId :: GuildId,
  mainRoomId :: ChannelId
} deriving (Show, Generic, FromJSON, ToJSON)

loadConfig :: IO (Maybe Config)
loadConfig = either (const Nothing) Just <$> decodeFileEither "config.yaml"

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
        (Nothing, _, _) -> print "[env] HCCBOT_ID is not set"
        (_, Nothing, _) -> print "[env] HCCBOT_TOKEN is not set"
        (_, _, Nothing) -> print "[env] GROQ_API_KEY is not set"

        (Just id_, Just token_, Just key_) -> do
          flag <- newMVar False

          void $ runDiscord $ def {
            discordToken = pack token_,
            discordOnEvent = eebot id_ key_ conf flag
          }

eebot :: String -> String -> Config -> MVar Bool -> Event -> DiscordHandler ()
eebot id_ key_ conf@Config{..} flag event = case event of
  Ready {} -> do
    print $ "[join] HCC eebot !!! uwu"
    print $ "[club] " <> ps (mainClubId)
    print $ "[room] " <> ps (mainRoomId)

    sumHistory key_ conf

    void $ liftIO $ forkIO $ forever $ do
      threadDelay (timeInterval * 60000000) -- 60s
      void $ swapMVar flag True

  MessageCreate msg@Message{..} -> do
    signal <- liftIO $ swapMVar flag False
    when signal $ sumHistory key_ conf

    when (not $ userIsBot messageAuthor) $ do
      let mention = pack $ "<@" <> id_ <> ">"

      guard (messageGuildId == Just (mainClubId))

      when (mention `isInfixOf` messageContent) $ do -- burn
        void $ restCall $ CreateReaction (messageChannelId, messageId) "fire"

      when (messageChannelId == mainRoomId && not (null messageContent)) $ do
        traverse_ (print . ("[log] " <>)) (formatMsg msg) -- peek

  _ -> return ()

sumHistory :: String -> Config -> DiscordHandler ()
sumHistory key_ conf = getHistory conf >>= getReport key_ conf

getHistory :: Config -> DiscordHandler Text
getHistory Config{..} = do
  print $ "[logs] start getting " <> ps maxHistory <> " msgs"

  msgs <- nextBatch mainRoomId maxHistory []
  let formatted = mapMaybe formatMsg msgs
      content = unlines $ formatted

  saveFile historyPath content

  return content

nextBatch :: ChannelId -> Int -> [Message] -> DiscordHandler [Message]
nextBatch _ rest acc | rest <= 0 = return (reverse acc)
nextBatch mainRoomId rest acc = do
  let size = min 100 rest
      point = case acc of
        [] -> LatestMessages
        ms -> BeforeMessage (messageId $ last ms)

  result <- restCall $ GetChannelMessages mainRoomId (size, point)

  liftIO $ threadDelay 500000 -- 0.5s

  case result of
    Left _ -> return (reverse acc)
    Right new | length new <= 0 -> return (reverse acc)
    Right new -> nextBatch mainRoomId (rest - length new) (acc <> new)

formatMsg :: Message -> Maybe Text
formatMsg Message{..} = do
  guard (not $ null messageContent)
  return (userName messageAuthor <> ": " <> messageContent)

getReport :: String -> Config -> Text -> DiscordHandler ()
getReport key_ conf@Config{..} hist = do
  print $ "[logs] start requesting " <> pack groqModel

  pmpt <- loadFile promptPath
  tile <- loadFile headerPath
  parsed <- parseTile conf tile

  body <- liftIO $ callGroq key_ groqModel . unpack $
    pmpt <> "\n\n" <> hist

  saveFile reportPath (parsed <> "\n\n" <> body)

parseTile :: Config -> Text -> DiscordHandler Text
parseTile Config{..} tile = do
  time <- getNowTime
  let rep = replace "{AI}" (pack groqModel)
          $ replace "{LEN}" (ps maxHistory)
          $ replace "{MIN}" (ps timeInterval)
          $ replace "{TIME}" (pack time) tile
  return rep

getNowTime :: DiscordHandler String
getNowTime = do
  utcNow <- liftIO getCurrentTime
  let tz = hoursToTimeZone 8
      cn = utcToLocalTime tz utcNow
  return $ formatTime defaultTimeLocale "%Y.%m.%d %H:%M:%S" cn

loadFile :: String -> DiscordHandler Text
loadFile path = do
  print $ "[logs] loaded " <> pack path
  liftIO $ decodeUtf8 <$> readFile path

saveFile :: String -> Text -> DiscordHandler ()
saveFile path text = do
  liftIO $ writeFile path (encodeUtf8 text)
  print $ "[logs] written to " <> pack path
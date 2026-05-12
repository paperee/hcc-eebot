{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE ScopedTypeVariables #-}

module Groq (callGroq) where

import Network.HTTP.Req

import Control.Applicative ((<|>))
import Data.Aeson
import Data.Aeson.Types (Parser, parseEither)
import Data.ByteString.Char8 (pack)
import Data.Text (Text)
import qualified Data.Vector as V

callGroq :: String -> String -> String -> IO Text
callGroq apiKey apiMod text = runReq defaultHttpConfig $ do
  let url = https "api.groq.com" /: "openai" /: "v1" /: "chat" /: "completions"
      body = ReqBodyJson $ object
        ["model" .= apiMod, "messages" .=
          [object ["role" .= ("user" :: String), "content" .= text]]]

  res <- req POST url body jsonResponse
    $ header "Authorization" ("Bearer " <> pack apiKey)

  let val = responseBody res :: Value
  case parseEither parseGroqContent val of
    Right content -> return content
    _ -> return ""

parseGroqContent :: Value -> Parser Text
parseGroqContent = withObject "Groq response" $ \o -> do
  choices <- o .: "choices"
  choice <- case choices of
    Array arr | not (V.null arr) -> pure (arr V.! 0)
    _ -> fail "missing choices"
  parseChoiceContent choice

parseChoiceContent :: Value -> Parser Text
parseChoiceContent = withObject "choice" $ \c ->
  (c .: "message" >>= (.: "content")) <|>
  (c .: "delta" >>= (.: "content"))

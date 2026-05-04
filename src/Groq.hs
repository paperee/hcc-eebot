{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE ScopedTypeVariables #-}

module Groq (callGroq) where

import Network.HTTP.Req

import Data.Aeson
import Data.Aeson.Types (parseEither)
import Data.ByteString.Char8 (pack)
import Data.Text (Text)
import Data.Vector ((!), null)
import Prelude hiding (null)

callGroq :: String -> String -> String -> IO Text
callGroq apiKey apiMod text = runReq defaultHttpConfig $ do
  let url = https "api.groq.com" /: "openai" /: "v1" /: "chat" /: "completions"
      body = ReqBodyJson $ object
        ["model" .= apiMod, "messages" .=
          [object ["role" .= ("user" :: String), "content" .= text]]]

  res <- req POST url body jsonResponse
    $ header "Authorization" ("Bearer " <> pack apiKey)

  let val = responseBody res :: Value
  case parseEither parseJSON val of
    Right (Object o) -> case parseEither (.: "choices") o of -- wtf
      Right (Array arr) | not (null arr) -> case arr ! 0 of -- lambda
        Object c -> case parseEither (.: "message") c of -- wssb nsfw
          Right (Object m) -> case parseEither (.: "content") m of
            Right (content :: Text) -> return content -- =v=
            _ -> return ""
          _ -> return ""
        _ -> return ""
      _ -> return ""
    _ -> return ""
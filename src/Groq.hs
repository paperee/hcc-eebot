{-# LANGUAGE OverloadedStrings #-}

module Groq (callGroq) where

import Network.HTTP.Req

import Data.Aeson ((.=), object, Value)
import Data.ByteString.Char8 (pack)

callGroq :: String -> String -> String -> IO Value
callGroq apiKey apiMod text = do
  runReq defaultHttpConfig $ do
    let url = https "api.groq.com" /: "openai" /: "v1" /: "chat" /: "completions"
        body = ReqBodyJson $ object
          ["model" .= apiMod, "messages" .=
            [object ["role" .= ("user" :: String), "content" .= text]]]

    res <- req POST url body jsonResponse
      $ header "Authorization" ("Bearer " <> pack apiKey)

    return $ responseBody res
# hcc-eebot
**_haskell chatrooms-club eebot !!! uwu_**

> 对 Chatrooms Club (CrC) 工会 general 频道近期的新消息进行汇总）

_该项目~~折磨人~~的开发过程见 [Wiki](https://github.com/paperee/hcc-eebot/wiki) 更新记录见 [CHANGELOG.md](https://github.com/paperee/hcc-eebot/blob/master/CHANGELOG.md)_

## hi yooooooo
- **Author**：[Paperee57](https://paperee.guru) _(ee)_
- **Started**：May 1, 2026 _(劳动节快乐~)_
- **Description**：Haskell 语言初尝试！_OvO_
- **Thanks**：[Discord](https://discord.com)，[Groq](https://groq.com)，[discord-haskell Docs](https://hackage-content.haskell.org/package/discord-haskell-1.18.0) 

## environment vars
> 写入环境变量的方式有很多种 请自行搜索查询…

1. 拥有 Discord 账号并在 [Discord 开发者平台](https://discord.com/developers/applications) 申请自己的 bot
2. 将 token 与 id 写入环境变量 `HCCBOT_TOKEN` 和 `HCCBOT_ID`
3. 注册 [Groq 平台](https://console.groq.com/keys) 并创建新的 API Key (有免费模型)
4. 将 API Key 写入环境变量 `GROQ_API_KEY`

## ./config.yaml file
> 工会和频道 id 可以在 Discord 的 web URL 中获取

1. _修改 `mainGuildId` 字段为 bot 加入的工会 id_
2. _修改 `mainChannelId` 字段为该工会其中某频道的 id_
3. _其他字段也可以修改 (但是没必要) 以下一一列举_

    - `timeInterval`: 每隔多少分钟请求历史记录并生成报告 (df: _60_)
    - `maxHistory`: 每次请求多少条历史记录 (df: _200_)
    - `historyPath`: 历史记录文件存放的路径 (df: _./uwu/history.txt_)
    - `reportPath`: 报告文件存放的路径 (df: _./uwu/report.txt_)
    - `promptPath`: 提示词从该路径读取 (df: _./uwu/prompt.txt_)

## stack built --fast
> 这是一个非常… 漫长的过程 长到足以让你从 Haskell 语言入门到入土

## stack exec hcc-eebot-exe
> 如果你使用 `stack built` 编译成功 执行该指令让它跑起来！uwu

**_一些输入/输出文件的示例：_**[history.txt](https://github.com/paperee/hcc-eebot/blob/master/uwu/history.txt)，[prompt.txt](https://github.com/paperee/hcc-eebot/blob/master/uwu/prompt.txt)，[report.md](https://github.com/paperee/hcc-eebot/blob/master/uwu/report.md) _(cool)_

# hcc-eebot

**_haskell chatrooms-club eebot !!! uwu_**

_一个对某工会某频道近期的新消息进行 AI 汇总的项目_

已部署至 [@MuRongPIG](https://github.com/MuRongPIG) 的服务器 (_Thank you~_)

生成的报告将自动发表至 [纸片君ee的博客: 聊天室时报！](https://blog.paperee.guru/essays/聊天室时报！)

## hi yooooooo

- **Author**：[Paperee57](https://paperee.guru) _(ee)_
- **Started**：May 1, 2026 _(劳动节快乐~)_
- **Description**：Haskell 语言初尝试！_OvO_
- **Thanks**：[Chatrooms Club](https://discord.com/channels/1059405085391728680/1143954723758669835)，[discord-haskell Docs](https://hackage-content.haskell.org/package/discord-haskell-1.18.0)

该项目~~折磨人~~的开发过程见 [Wiki](https://github.com/paperee/hcc-eebot/wiki) 更新记录见 [CHANGELOG.md](https://github.com/paperee/hcc-eebot/blob/master/CHANGELOG.md)

## environment vars

> 请自行搜索/查询写入环境变量的方式 有很多种

1. 拥有 Discord 账号并在 [Discord 开发者平台](https://discord.com/developers/applications) 申请自己的 bot
2. 将 token 与 id 写入环境变量 `HCCBOT_TOKEN` 和 `HCCBOT_ID`
3. 注册 [Groq 平台](https://console.groq.com/keys) 并创建新的 API Key (有免费模型)
4. 将 API Key 写入环境变量 `GROQ_API_KEY`

## ./config.yaml file

> 工会和频道 id 可以在 Discord 的 web URL 中获取

1. _修改 `mainGuildId` 字段为 bot 加入的工会 id_
2. _修改 `mainChannelId` 字段为该工会其中某频道的 id_
3. _其他字段也可以修改 (但是没必要) 以下一一列举_
   - `timeInterval`: 每隔多少分钟请求历史记录并生成报告 (_60_)
   - `maxHistory`: 每次请求多少条历史记录 (_200_)
   - `historyPath`: 历史记录文件存放的路径 (_./uwu/history.txt_)
   - `reportPath`: 报告文件存放的路径 (_./uwu/report.md_)
   - `promptPath`: 提示词从该路径读取 (_./uwu/prompt.txt_)
   - `headerPath`: 报告头部从该路径读取 (_./uwu/header.md_)
   - `groqModel`：Groq 平台的大模型 (_openai/gpt-oss-120b_)

## stack built --fast

> 编译是一个非常… 漫长的过程 足以让你从 Haskell 语言入门到入土

> 不过 首先 你应该想办法安装并配置 Stack 环境

## stack exec hcc-eebot-exe

> 如果你使用 `stack built` 编译成功 执行该指令让它跑起来！uwu

**_输入/输出文件的示例：_**[prompt.txt](https://github.com/paperee/hcc-eebot/blob/master/uwu/prompt.txt)，[header.md](https://github.com/paperee/hcc-eebot/blob/master/uwu/header.md)，[history.txt](https://github.com/paperee/hcc-eebot/blob/master/uwu/history.txt)，[report.md](https://github.com/paperee/hcc-eebot/blob/master/uwu/report.md)

# hcc-eebot

**_haskell chatrooms-club eebot !!! uwu_**

> 汇总 Discord Chatrooms Club (CrC) 工会 general 频道近期的新消息

## hi yooooooo

- **Author**: Paperee57 _(ee)_
- **Started**: May 1, 2026 _(劳动节快乐~)_
- **Decs**: Haskell 语言初尝试！_OvO_

### environment vars

**_(1) 在 [Discord 开发者平台](https://discord.com/developers/) 申请自己的 bot：_**

将 token 与 id 写入环境变量 `HCCBOT_TOKEN` 和 `HCCBOT_ID`

_**(2) 在 [Groq 平台](https://console.groq.com/) 创建新的 API Key (有免费模型)：**_

将 API Key 写入环境变量 `GROQ_API_KEY`

> 写入环境变量的方式有很多种 请自行搜索查询…

### ./config.yaml file

_(1) 修改 `mainGuildId` 字段为 bot 加入的工会 id_

_(2) 修改 `mainChannelId` 字段为该工会其中某频道的 id_

> 工会和频道 id 可以在 Discord 的 web URL 中获取

_(3) 其他字段也可以修改 (但是没必要) 以下一一列举_

- `timeInterval`: 每隔多少分钟请求历史记录并生成报告 (df: _60_)
- `maxHistory`: 每次请求多少条历史记录 (df: _200_)
- `historyPath`: 历史记录文件存放的路径 (df: _./uwu/history.txt_)
- `reportPath`: 报告文件存放的路径 (df: _./uwu/report.txt_)
- `promptPath`: 提示词从该路径读取 (df: _./uwu/prompt.txt_)

### stack built --fast

> 这是一个非常… 漫长的过程 长到足以让你从 Haskell 语言入门到入土

### stack exec hcc-eebot-exe

> 如果你使用 `stack built` 编译成功 执行该指令让它跑起来！uwu

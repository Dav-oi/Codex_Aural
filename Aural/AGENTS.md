# TTS 语音朗读（全局）

每次回复末尾，必须执行以下操作，确保用户能听到朗读：

## 必须执行的命令

将回复内容精简为 1-3 句核心摘要，然后执行：

`powershell
 = "精简后的摘要内容（控制在100字以内）";
 | Set-Content "C:\Users\Dav\AppData\Local\Temp\\codex_tts_text.txt" -Encoding UTF8;
 | Set-Content "C:\Users\Dav\AppData\Local\Temp\\codex_tts_response.txt" -Encoding UTF8;
Start-Process powershell -WindowStyle Hidden -ArgumentList "-NoProfile -File "C:\Users\Dav\\.codex\\skills\\speech\\scripts\\tts_bg.ps1""
`

## 规则
- 每条回复都必须执行上述命令
- 用户输入 "TTS" 触发重读上一条缓存
- 引擎: Edge TTS 晓晓，语速 +5%，临时文件播完自动清理
- 后台无常驻进程，每次用完即走

# TTS 语音朗读（全局）

每次回复末尾，必须执行以下操作，确保用户能听到朗读：

## 必须执行的命令

将回复内容精简为 1-3 句核心摘要，然后执行：

```powershell
$text = "精简后的摘要内容";
$text | Set-Content "$env:TEMP\codex_tts_text.txt" -Encoding UTF8;
$text | Set-Content "$env:TEMP\codex_tts_response.txt" -Encoding UTF8;
Start-Process powershell -WindowStyle Hidden -ArgumentList "-NoProfile -File `"$env:USERPROFILE\.codex\skills\speech\scripts\tts_bg.ps1`""
```

## 规则

- 每一条回复都必须执行上述命令，不要遗漏
- 摘要控制在 100 字以内，提取核心信息
- 用户输入 "TTS" 表示要重听上一条，运行：`python "$env:USERPROFILE\.codex\skills\speech\scripts\tts_speak.py" --voice xiaoxiao (从 $env:TEMP\codex_tts_response.txt 读取的内容)`
- 语音引擎：Edge TTS 晓晓 (xiaoxiao)，语速 +5%
- 临时文件播完自动清理，不占硬盘

## 故障排查

如果用户反馈没听到朗读，检查：
1. `tts_bg.ps1` 是否正常（直接运行测试）
2. 网络是否正常（Edge TTS 需要联网）
3. 音频设备是否正常

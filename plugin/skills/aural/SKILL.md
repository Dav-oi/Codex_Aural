---
name: aural
description: TTS voice narration for Codex responses using Edge TTS (xiaoxiao) with automatic fallback to Windows built-in TTS. Use when the user wants every assistant response to be read aloud, needs spoken output for accessibility, or wants auto-summarization before speech. Triggers on any task where audio narration is expected. Also use for install/config of TTS narration.
---

# Aural — 让 Codex 开口说话

全局语音朗读技能。每条回复末尾自动朗读，支持 Edge TTS 在线语音和 Windows 离线语音。

## 工作流程

1. 每次回复后，将回复内容精简为 1-3 句核心摘要（≤100 字）
2. 写入临时文件，触发后台朗读
3. 后台进程调用 Edge TTS 生成语音 → MCI 播放 → 自动清理

## 必须执行的命令

在每条回复末尾执行：

```powershell
$text = "精简的摘要内容";
if (-not $env:CODEX_HOME) { $env:CODEX_HOME = "$env:USERPROFILE\.codex" }; $text | Set-Content "$env:TEMP\codex_tts_text.txt" -Encoding UTF8;
$text | Set-Content "$env:TEMP\codex_tts_response.txt" -Encoding UTF8;
Start-Process powershell -NoNewWindow `
  -ArgumentList "-NoProfile -File `"$env:CODEX_HOME\skills\aural\scripts\tts_bg.ps1`""
```

## 规则

- **每条回复都必须执行**，无例外
- 摘要控制在 100 字以内，提取核心信息
- 用户输入 "TTS" 表示重听上一条
- 引擎：Edge TTS 晓晓 (xiaoxiao)，语速 +5%
- 网络不通时自动降级到 Windows 内置 TTS
- 临时文件播完自动清理

## 并行处理机制（学习备注）

1. `scripts/tts_bg.ps1` 内置串行队列，避免多任务同时朗读造成重叠。
2. 并发时会在正文前播报可理解的来源名：`来自 <项目或对话名>`。
3. 来源名优先使用 `AURAL_SOURCE_NAME`，其次尝试 Codex 对话/项目环境变量，再回退到当前项目目录名。
4. 来源名过长时会自动压缩为较短名称；只有没有可读名称时才回退到短对话 ID。

## 安装

### 自动安装（推荐）

```powershell
& "$env:CODEX_HOME\skills\aural\scripts\install.ps1"
```

一键检测 Python、安装 edge_tts、验证引擎。

### 手动安装

```bash
pip install edge_tts
```

### 自动降级

`tts_bg.ps1` 每次启动时会自动检测 `edge_tts` 是否可用：
- **已安装** → 使用 Edge TTS 晓晓（在线，音质好）
- **未安装** → 自动尝试 `pip install edge_tts`
- **安装失败/无网络** → 自动降级到 Windows 内置 TTS（离线）

无需任何手动配置，开箱即用。

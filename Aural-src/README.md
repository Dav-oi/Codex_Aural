# Aural — 让 Codex 开口说话！！！
[Dav-oi/Codex_Aural](https://github.com/Dav-oi/Codex_Aural)

---

## 【功能概述】

1. Aural 言简意赅 而非死板朗读！
2. Edge TTS（默认） — 微软 Edge 在线语音合成，音质好，需联网
3. Windows System TTS — 系统内置语音，离线可用，响应快

---

## 架构

```
回复文本 → tts_bg.ps1 → tts_speak.py → Edge TTS API → MP3 → play_mp3.ps1 (MCI) → 扬声器
```

## 快速开始

```bash
# 1. 安装依赖
pip install -r requirements.txt

# 2. 朗读一段文字
python scripts/tts_speak.py --voice xiaoxiao "你好，这是 Codex 语音朗读"

# 3. 使用 Windows 内置 TTS（无需网络）
python scripts/tts_speak.py --system "离线朗读测试"

# 4. 自动摘要 + 朗读
python scripts/tts_speak.py -c "这是一段很长的文字..."

# 5. 列出可用语音
python scripts/tts_speak.py --list
```

## 可用语音

| 名称 | Edge TTS Voice |
|------|---------------|
| xiaoxiao | zh-CN-XiaoxiaoNeural |
| xiaoyi | zh-CN-XiaoyiNeural |
| yunjian | zh-CN-YunjianNeural |
| yunxi | zh-CN-YunxiNeural |
| yunxia | zh-CN-YunxiaNeural |
| yunyang | zh-CN-YunyangNeural |

## 一键安装

```bash
python scripts/tts_install.py
```

自动完成：安装依赖 → 部署脚本 → 配置 AGENTS.md → 配置 PowerShell Profile

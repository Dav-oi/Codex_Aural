# Aural — Codex 全局语音朗读

让 Codex 所有对话自动朗读回复。

---

## 功能

- Edge TTS 晓晓神经语音，自然流畅
- 每条对话回复自动触发朗读，后台即用即走
- 临时文件自动清理，不占硬盘
- 支持 `tts` / `tts-last` 快捷命令

---

## 安装

### 前置条件
- Windows 10/11
- Python 3.10+
- Codex CLI / Desktop

### 方式一：一键安装
```powershell
pip install edge_tts
python tts_install.py
```

### 方式二：Setup 安装器
运行 `Aural-Setup-v1.0.exe`，按向导完成安装。

---

## 使用

| 操作 | 方法 |
|------|------|
| 自动朗读 | 无需操作，每次回复自动触发 |
| 手动朗读 | `tts "要朗读的文字"` |
| 重听上一条 | 输入 `TTS` 或运行 `tts-last` |

---

## 文件结构

```
.codex\skills\speech\scripts\
├── tts_speak.py     核心 TTS 引擎
├── play_mp3.ps1     MCI 音频播放器
└── tts_bg.ps1       后台启动器
```

---

## 故障排查

| 现象 | 解决 |
|------|------|
| 听不到朗读 | 检查网络连接（Edge TTS 需联网） |
| 听不到朗读 | 检查系统音量与播放设备 |
| 脚本被禁止 | `Set-ExecutionPolicy RemoteSigned -Scope CurrentUser` |

---

## 作者

Dav / Dave  — v1.0

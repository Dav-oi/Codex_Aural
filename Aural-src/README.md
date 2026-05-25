# Aural — 让 Codex 开口说话

[![Release](https://img.shields.io/badge/Release-v1.4-%23D27800)](https://github.com/Dave-oioioi/Codex_Aural/releases/tag/Latest-Version)
[![License](https://img.shields.io/badge/License-MIT-green)](./LICENSE.txt)

[Dave-oioioi/Codex_Aural](https://github.com/Dave-oioioi/Codex_Aural)

---

## 功能概述

1. **言简意赅** — 自动摘要后再朗读，而非死板念全文
2. **Edge TTS**（默认）— 微软 Edge 在线语音合成，晓晓 (xiaoxiao)，音质好
3. **Windows System TTS** — 系统内置离线语音，无网络自动降级
4. **并行防重叠** — 串行队列播放，多任务并发时播报对话来源
5. **全局注册** — 安装后自动写入 `~/.codex/AGENTS.md`，Codex 默认启用朗读

---

## 快速安装

### 方式一：一键安装包（推荐）

下载 [Aural-Setup-v1.4.exe](https://github.com/Dave-oioioi/Codex_Aural/releases/download/Latest-Version/Aural-Setup-v1.4.exe)，双击运行即可。安装完成后：
- 自动安装 `edge_tts` 依赖
- 自动注册到 Codex 全局 `AGENTS.md`
- 重启终端即可生效

### 方式二：手动安装 Skill

```powershell
# 1. 将 skill 放入 Codex skills 目录
Copy-Item -Recurse aural-plugin/skills/aural/ $env:CODEX_HOME\skills\aural-skill\

# 2. 运行安装脚本（含 AGENTS.md 注册）
& "$env:CODEX_HOME\skills\aural-skill\scripts\install.ps1"

# 3. 重启终端
```

---

## 仓库目录

| 目录 | 说明 |
|------|------|
| `Aural-exe/` | Inno Setup 安装包工程 + 编译产物 |
| `Aural-src/` | 源码工程（VS Code 可打开调试） |
| `aural-plugin/` | Codex Plugin 包（含 plugin.json + skill） |

---

## 技术栈

- **TTS 引擎**: Edge TTS (edge_tts) / Windows SAPI
- **音频播放**: Windows MCI API (winmm.dll)
- **后台队列**: PowerShell 互斥锁 + 文件队列
- **安装包**: Inno Setup 6
- **全局集成**: `~/.codex/AGENTS.md` 自动注册

---

## License

MIT © [Dave-oioioi](https://github.com/Dave-oioioi)

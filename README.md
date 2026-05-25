# Aural — 让 Codex 开口说话

[![Release](https://img.shields.io/badge/Release-v1.4.1-%23D27800)](https://github.com/Dave-oioioi/Codex_Aural/releases/tag/Latest-Version)
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

下载 [Aural-Setup-v1.4.1.exe](https://github.com/Dave-oioioi/Codex_Aural/releases/download/Latest-Version/Aural-Setup-v1.4.1.exe)，双击运行即可。

- **零依赖**：内置 Python 3.12 便携版 + `edge_tts` 预装，无需手动配置
- 自动注册到 Codex 全局 `AGENTS.md`
- 重启终端即可生效

### 方式二：手动安装 Skill

```powershell
# 1. 将 skill 放入 Codex skills 目录
Copy-Item -Recurse plugin/skills/aural/ $env:CODEX_HOME\skills\aural-skill\

# 2. 运行安装脚本（含 AGENTS.md 注册）
& "$env:CODEX_HOME\skills\aural-skill\scripts\install.ps1"

# 3. 重启终端
```

---

## 仓库目录

| 目录 | 说明 |
|------|------|
| `plugin/` | Codex Plugin — 唯一源（skill + plugin.json） |
| `installer/` | Inno Setup 打包脚本 |
| `tools/` | 开发工具 + 辅助脚本 |
| `python-embed/` | Python 3.12 便携版（打包用，不入库） |
| `releases/` | 编译产物 .exe（不入库） |
------|------|
| `plugin/` | Codex Plugin — 唯一源（含 skill + plugin.json） |
| `python-embed/` | Python 3.12 便携版 + edge_tts（打包用，不入库） |
| `releases/` | 编译产物 .exe（不入库） |

---

## 技术栈

- **TTS 引擎**: Edge TTS (edge_tts) / Windows SAPI
- **音频播放**: pygame mixer（静默，无窗口弹出）
- **后台队列**: PowerShell 互斥锁 + 文件队列
- **安装包**: Inno Setup 6
- **全局集成**: `~/.codex/AGENTS.md` 自动注册

---

## License

MIT © [Dave-oioioi](https://github.com/Dave-oioioi)


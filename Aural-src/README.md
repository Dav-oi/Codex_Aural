# Aural — 让 Codex 开口说话！！！
[Dave-oioioi/Codex_Aural](https://github.com/Dave-oioioi/Codex_Aural)

---

## 【功能概述】

1. Aural 言简意赅 而非死板朗读！
2. Edge TTS（默认） — 微软 Edge 在线语音合成，音质好，需联网
3. Windows System TTS — 系统内置语音，离线可用，响应快

---

## 【使用说明】

安装后重启终端，Codex 每条回复自动朗读。

```powershell
tts "你好世界"     # 手动朗读
tts-last           # 重听上一条
TTS                # 对话中重听
```

---

## 【学习备注：并行防重叠机制】

1. `tts_bg.ps1` 采用“文件队列 + 全局互斥锁（Global\CodexAuralTtsQueue）”实现串行播放。
2. 每次触发先入队，不直接播放；抢不到锁的进程立即退出，由持锁进程顺序消费队列。
3. 当检测到并行场景时（队列中存在多个消息），朗读前自动加提示：`来自对话 <thread-id>`。
4. 对话来源读取环境变量 `CODEX_THREAD_ID`，便于多会话并发时区分来源。

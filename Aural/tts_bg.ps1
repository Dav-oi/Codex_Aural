<#
.SYNOPSIS
    Aural TTS 后台触发器 — Codex 回复后自动朗读

.DESCRIPTION
    由 Codex AGENTS.md 配置在每条回复末尾触发。
    
    工作流程：
      1. 检查临时文件 %TEMP%\codex_tts_text.txt 是否存在
      2. 读取文本内容
      3. 删除文本文件（避免重复朗读）
      4. 调用 tts_speak.py 执行语音合成和播放
      5. 记录日志到 %TEMP%\tts_bg.log
    
    设计要点：
      - 用完即走，无常驻进程（每次由 Start-Process 启动）
      - 异步非阻塞，不影响 Codex 回复速度
      - 错误不抛出，全部记录到日志

.NOTES
    触发方式（由 Codex AGENTS.md 自动执行）：
      Start-Process powershell -WindowStyle Hidden -File "tts_bg.ps1"
#>

# =============================================================================
# 路径配置
# =============================================================================

# 临时文本文件：Codex 回复前将摘要写入此文件
$textFile = "$env:TEMP\codex_tts_text.txt"

# Python 解释器路径（自动检测）
$python = (Get-Command python).Source

# tts_speak.py 脚本路径（部署在 Codex skills 目录）
$ttsScript = "$env:USERPROFILE\.codex\skills\speech\scripts\tts_speak.py"

# =============================================================================
# 主逻辑
# =============================================================================

if (Test-Path $textFile) {
    # 1. 读取 Codex 写入的朗读文本
    $text = Get-Content $textFile -Raw -Encoding UTF8
    
    # 2. 立即删除文本文件（防止下次误读或重复朗读）
    Remove-Item $textFile -Force
    
    if ($text.Trim()) {
        # 3. 调用 Python 脚本：Edge TTS 晓晓语音 + 自动摘要
        #    --voice xiaoxiao  使用晓晓语音
        #    --condense        自动压缩到 150 字以内
        $result = & $python $ttsScript --voice xiaoxiao --condense $text 2>&1
        $exitCode = $LASTEXITCODE
        
        # 4. 记录日志（调试用）
        "$(Get-Date) | exit=$exitCode | $result" | Out-File "$env:TEMP\tts_bg.log" -Append -Encoding UTF8
    }
}

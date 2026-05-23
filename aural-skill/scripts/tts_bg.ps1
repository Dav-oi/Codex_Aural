<#
.SYNOPSIS
    Aural TTS 后台触发器 — Codex 回复后自动朗读

.DESCRIPTION
    由 Aural Skill 的 SKILL.md 配置在每条回复末尾触发。
    
    工作流程：
      1. 检查临时文件 %TEMP%\codex_tts_text.txt
      2. 读取文本 → 删除文件
      3. 调用 tts_speak.py → Edge TTS → MCI 播放
      4. 记录日志

    设计要点：用完即走，无驻进程，异步非阻塞。
#>

# ── 路径：自动定位 Skill 目录 ──
$skillDir = if ($env:CODEX_HOME) { "$env:CODEX_HOME\skills\aural" } else { "$env:USERPROFILE\.codex\skills\aural" }
$python = (Get-Command python -ErrorAction SilentlyContinue).Source
$ttsScript = "$skillDir\scripts\tts_speak.py"
$textFile = "$env:TEMP\codex_tts_text.txt"

if (-not $python) {
    "$(Get-Date) | ERROR: Python not found" | Out-File "$env:TEMP\tts_bg.log" -Append -Encoding UTF8
    exit 1
}

if (Test-Path $textFile) {
    $text = Get-Content $textFile -Raw -Encoding UTF8
    Remove-Item $textFile -Force
    if ($text.Trim()) {
        $result = & $python $ttsScript --voice xiaoxiao --condense $text 2>&1
        "$(Get-Date) | exit=$LASTEXITCODE | $result" | Out-File "$env:TEMP\tts_bg.log" -Append -Encoding UTF8
    }
}

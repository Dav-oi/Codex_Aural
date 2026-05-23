<#
.SYNOPSIS
    Aural TTS 终端命令 — PowerShell Profile 配置

.DESCRIPTION
    安装到 PowerShell Profile 后提供以下命令：
    
      tts "文字"     — 朗读指定文字（默认 Edge TTS 晓晓）
      tts -System    — 使用 Windows 离线 TTS
      tts -c         — 自动摘要后朗读
      tts-last       — 重读上一条 Codex 回复
      say            — tts 别名
      echo "文字" | tts — 管道输入

.NOTES
    安装路径: ~\Documents\WindowsPowerShell\profile.ps1
    每次打开 PowerShell 终端自动加载
#>

# =============================================================================
# 路径配置
# =============================================================================

# Python TTS 脚本位置
$TTS_SCRIPT = "$env:USERPROFILE\.codex\skills\speech\scripts\tts_speak.py"

# 上一条回复缓存文件（由 Codex AGENTS.md 写入）
$TTS_CACHE  = "$env:TEMP\codex_tts_response.txt"

# =============================================================================
# 命令：tts — 朗读文字
# =============================================================================
function global:tts {
    param(
        [switch]$System,    # 使用 Windows 系统离线 TTS
        [string]$Voice,     # 指定 Edge TTS 语音名
        [string]$Rate,      # 指定语速
        [Parameter(ValueFromPipeline, ValueFromRemainingArguments)]$Text  # 朗读文本（支持管道）
    )
    
    # 构建 Python 命令
    $cmd = @("python", $TTS_SCRIPT)
    if ($System) { $cmd += "--system" }
    if ($Voice)  { $cmd += "--voice"; $cmd += $Voice }
    if ($Rate)   { $cmd += "--rate"; $cmd += $Rate }
    
    if ($Text) {
        # 直接参数模式：tts "你好世界"
        $cmd += $Text
        & $cmd[0] $cmd[1..$cmd.Count]
    } else {
        # 管道输入模式：echo "你好" | tts
        $input | & python $TTS_SCRIPT
    }
}

# =============================================================================
# 命令：tts-last — 重读上一条 Codex 回复
# =============================================================================
function global:tts-last {
    if (Test-Path $TTS_CACHE) {
        $text = Get-Content $TTS_CACHE -Raw -Encoding UTF8
        
        if ($text.Trim()) {
            # 用晓晓语音朗读缓存内容
            & python $TTS_SCRIPT --voice xiaoxiao $text
        } else {
            Write-Host "No cached response." -ForegroundColor Yellow
        }
    } else {
        Write-Host "No cache file." -ForegroundColor Yellow
    }
}

# =============================================================================
# 别名与加载提示
# =============================================================================

# say = tts 的快捷别名
Set-Alias -Name say -Value tts -Scope Global

# 终端启动提示
Write-Host "TTS ready!  tts | tts-last" -ForegroundColor Green

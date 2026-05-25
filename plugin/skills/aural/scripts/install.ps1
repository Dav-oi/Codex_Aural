<#
.SYNOPSIS
    Aural Skill 一键依赖安装脚本

.DESCRIPTION
    自动检测并安装 Aural TTS 所需的所有依赖：
      1. 检测 Python 是否可用
      2. 安装/升级 edge_tts 包
      3. 验证 Edge TTS 引擎可正常工作
      4. 检查 Windows 内置 TTS 作为离线后备
      5. 注册到 Codex 全局 AGENTS.md

    运行方式：
      powershell -File install.ps1
#>

param(
    [switch]$Quiet
)

$ErrorActionPreference = "Continue"
$skillDir = Split-Path -Parent $MyInvocation.MyCommand.Path

function Write-Step {
    param([string]$Message, [string]$Status)
    if (-not $Quiet) {
        $icon = switch ($Status) {
            "ok"    { "[OK]" }
            "warn"  { "[WARN]" }
            "fail"  { "[FAIL]" }
            "info"  { "[INFO]" }
            default { "[ .. ]" }
        }
        Write-Host "$icon $Message"
    }
}

# ============================================================
# Step 1: 检测 Python（缺失时自动通过 winget 安装）
# ============================================================
$python = $null
try {
    $python = (Get-Command python -ErrorAction Stop).Source
    $pyVer = & python --version 2>&1
    Write-Step "Python found: $pyVer" "ok"
} catch {
    try {
        $python = (Get-Command python3 -ErrorAction Stop).Source
        $pyVer = & python3 --version 2>&1
        Write-Step "Python3 found: $pyVer" "ok"
    } catch {
        Write-Step "Python not found, attempting winget auto-install..." "warn"
        try {
            $wingetResult = winget install Python.Python.3.12 --silent --accept-package-agreements --accept-source-agreements 2>&1
            if ($LASTEXITCODE -eq 0) { Write-Step "Python 3.12 installed via winget" "ok" }
            else { throw "winget failed" }
        } catch {
            Write-Step "Python not installed. Please install manually from https://python.org" "fail"
            exit 1
        }
        # Refresh PATH and re-detect
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
        try {
            $python = (Get-Command python -ErrorAction Stop).Source
            Write-Step "Python detected after install: $python" "ok"
        } catch {
            Write-Step "Python installed but not found in PATH. Please reboot." "fail"
            exit 1
        }
    }
}# ============================================================
# Step 2: 安装 edge_tts
# ============================================================
Write-Step "Installing edge_tts..." "info"
$pipArgs = @("-m", "pip", "install", "edge_tts", "--quiet", "--disable-pip-version-check")
$result = & python $pipArgs 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Step "edge_tts installed successfully" "ok"
} else {
    $pipArgs += "--user"
    $result = & python $pipArgs 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Step "edge_tts installed (user scope)" "ok"
    } else {
        Write-Step "edge_tts install failed. Offline system TTS will be used as fallback." "warn"
        if (-not $Quiet) { Write-Host "  Error: $result" }
    }
}

# ============================================================
# Step 3: 验证 Edge TTS
# ============================================================
if (Test-Path (Join-Path $skillDir "tts_speak.py")) {
    $verifyResult = & python -c "import edge_tts; print('OK')" 2>&1
    if ($verifyResult -eq "OK") {
        Write-Step "Edge TTS engine verified" "ok"
    } else {
        Write-Step "Edge TTS import check failed, will use system TTS fallback" "warn"
    }
} else {
    Write-Step "tts_speak.py not found" "fail"
}

# ============================================================
# Step 4: 检查系统 TTS 后备
# ============================================================
try {
    Add-Type -AssemblyName System.Speech -ErrorAction Stop
    $synth = New-Object System.Speech.Synthesis.SpeechSynthesizer
    $voice = $synth.GetInstalledVoices() | Where-Object { $_.VoiceInfo.Culture.Name -like "zh-*" } | Select-Object -First 1
    if ($voice) {
        Write-Step "Windows system TTS (zh-CN) available as offline fallback" "ok"
    } else {
        Write-Step "No Chinese system voice found, offline fallback limited" "warn"
    }
    $synth.Dispose()
} catch {
    Write-Step "System.Speech not available on this system" "warn"
}

# ============================================================
# Step 5: 注册到 Codex 全局 AGENTS.md
# ============================================================
$codexHome = if ($env:CODEX_HOME) { $env:CODEX_HOME } else { "$env:USERPROFILE\.codex" }
$agentsFile = "$codexHome\AGENTS.md"

$auralBlock = @"

## Aural TTS — 全局语音朗读

每次回复后自动使用 Aural 进行语音朗读：

1. 将回复内容精简为 1-3 句核心摘要（≤100 字）
2. 写入临时文件触发后台朗读
3. 引擎：Edge TTS 晓晓 (xiaoxiao)，离线自动降级到系统 TTS
4. 每次对话回复末尾都必须执行

触发方式：参照 aural 的 SKILL.md 执行 TTS 触发命令。
"@

if (-not (Test-Path $agentsFile)) {
    "# Global AGENTS.md`n`n$auralBlock" | Out-File $agentsFile -Encoding UTF8
    Write-Step "Created global AGENTS.md with Aural registration" "ok"
} else {
    $current = Get-Content $agentsFile -Raw -Encoding UTF8
    if ($current -match "## Aural TTS") {
        Write-Step "Aural already registered in AGENTS.md" "ok"
    } else {
        "`n`n$auralBlock" | Out-File $agentsFile -Append -Encoding UTF8
        Write-Step "Aural registered in global AGENTS.md" "ok"
    }
}

# ============================================================
# Done
# ============================================================
if (-not $Quiet) {
    Write-Host ""
    Write-Host "=== Aural installation complete ===" -ForegroundColor Green
    Write-Host "  Primary engine : Edge TTS (xiaoxiao)"
    Write-Host "  Fallback       : Windows built-in TTS"
    Write-Host "  AGENTS.md      : registered"
    Write-Host "  Scripts        : $skillDir"
}


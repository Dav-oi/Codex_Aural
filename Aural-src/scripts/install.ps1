<#
.SYNOPSIS
    Aural Skill 一键依赖安装脚本

.DESCRIPTION
    自动检测并安装 Aural TTS 所需的所有依赖：
      1. 检测 Python 是否可用
      2. 安装/升级 edge_tts 包
      3. 验证 Edge TTS 引擎可正常工作
      4. 检查 Windows 内置 TTS 作为离线后备

    运行方式：
      powershell -File install.ps1
    或从 SKILL.md 触发：
      & "$env:CODEX_HOME\skills\aural-skill\scripts\install.ps1"
#>

param(
    [switch]$Quiet     # 静默模式：减少输出，适合自动触发
)

$ErrorActionPreference = "Continue"
$skillDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$skillRoot = Split-Path -Parent $skillDir

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
# Step 1: 检测 Python
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
        Write-Step "Python not found. Please install Python 3.8+ from https://python.org" "fail"
        exit 1
    }
}

# ============================================================
# Step 2: 安装 edge_tts
# ============================================================
Write-Step "Installing edge_tts..." "info"
$pipArgs = @("-m", "pip", "install", "edge_tts", "--quiet", "--disable-pip-version-check")
$result = & python $pipArgs 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Step "edge_tts installed successfully" "ok"
} else {
    # 重试：有时需要 --user
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
$verifyScript = Join-Path $skillDir "tts_speak.py"
if (Test-Path $verifyScript) {
    $verifyResult = & python -c "import edge_tts; print('OK')" 2>&1
    if ($verifyResult -eq "OK") {
        Write-Step "Edge TTS engine verified" "ok"
    } else {
        Write-Step "Edge TTS import check failed, will use system TTS fallback" "warn"
    }
} else {
    Write-Step "tts_speak.py not found at: $verifyScript" "fail"
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
# Done
# ============================================================
if (-not $Quiet) {
    Write-Host ""
    Write-Host "=== Aural installation complete ===" -ForegroundColor Green
    Write-Host "  Primary engine : Edge TTS (xiaoxiao)"
    Write-Host "  Fallback       : Windows built-in TTS"
    Write-Host "  Scripts        : $skillDir"
}

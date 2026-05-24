<#
.SYNOPSIS
    Aural TTS 后台触发器（串行队列版）

.DESCRIPTION
    使用“文件队列 + 全局互斥锁”确保并发触发时按顺序朗读，避免语音重叠。
#>

$textFile = "$env:TEMP\codex_tts_text.txt"
$queueDir = "$env:TEMP\codex_tts_queue"
$logFile = "$env:TEMP\tts_bg.log"
$mutexName = "Global\CodexAuralTtsQueue"

$skillDir = if ($env:CODEX_HOME) { "$env:CODEX_HOME\skills\aural" } else { "$env:USERPROFILE\.codex\skills\aural" }
$python = (Get-Command python -ErrorAction SilentlyContinue).Source
$ttsScript = "$skillDir\scripts\tts_speak.py"

if (-not $python) {
    "$(Get-Date) | ERROR: Python not found" | Out-File $logFile -Append -Encoding UTF8
    exit 1
}

if (-not (Test-Path $queueDir)) {
    New-Item -Path $queueDir -ItemType Directory -Force | Out-Null
}

function Add-ToQueue {
    param([string]$Content)
    if (-not $Content -or -not $Content.Trim()) {
        return
    }
    $name = "{0:yyyyMMdd_HHmmss_fff}_{1}.txt" -f (Get-Date), ([Guid]::NewGuid().ToString("N"))
    $path = Join-Path $queueDir $name
    $Content | Set-Content $path -Encoding UTF8
}

if (Test-Path $textFile) {
    $text = Get-Content $textFile -Raw -Encoding UTF8
    Remove-Item $textFile -Force -ErrorAction SilentlyContinue
    Add-ToQueue -Content $text
}

$mutex = New-Object System.Threading.Mutex($false, $mutexName)
$hasLock = $false

try {
    $hasLock = $mutex.WaitOne(0)
    if (-not $hasLock) {
        exit 0
    }

    while ($true) {
        $next = Get-ChildItem $queueDir -Filter *.txt -ErrorAction SilentlyContinue |
            Sort-Object LastWriteTime, Name |
            Select-Object -First 1

        if (-not $next) {
            break
        }

        try {
            $content = Get-Content $next.FullName -Raw -Encoding UTF8
            if ($content -and $content.Trim()) {
                $result = & $python $ttsScript --voice xiaoxiao --condense $content 2>&1
                "$(Get-Date) | exit=$LASTEXITCODE | file=$($next.Name) | $result" | Out-File $logFile -Append -Encoding UTF8
            }
        } finally {
            Remove-Item $next.FullName -Force -ErrorAction SilentlyContinue
        }
    }
} finally {
    if ($hasLock) {
        $mutex.ReleaseMutex() | Out-Null
    }
    $mutex.Dispose()
}

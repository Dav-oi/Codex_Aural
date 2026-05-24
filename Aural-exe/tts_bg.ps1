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
$threadId = if ($env:CODEX_THREAD_ID) { $env:CODEX_THREAD_ID } else { "unknown" }

$python = (Get-Command python -ErrorAction SilentlyContinue).Source
$ttsScript = "$env:USERPROFILE\.codex\skills\speech\scripts\tts_speak.py"

if (-not $python) {
    "$(Get-Date) | ERROR: Python not found" | Out-File $logFile -Append -Encoding UTF8
    exit 1
}

if (-not (Test-Path $queueDir)) {
    New-Item -Path $queueDir -ItemType Directory -Force | Out-Null
}

function Add-ToQueue {
    param(
        [string]$Content,
        [string]$Thread
    )
    if (-not $Content -or -not $Content.Trim()) {
        return
    }
    $name = "{0:yyyyMMdd_HHmmss_fff}_{1}.txt" -f (Get-Date), ([Guid]::NewGuid().ToString("N"))
    $path = Join-Path $queueDir $name
    $payload = @{
        thread = $Thread
        text = $Content
    } | ConvertTo-Json -Compress
    $payload | Set-Content $path -Encoding UTF8
}

if (Test-Path $textFile) {
    $text = Get-Content $textFile -Raw -Encoding UTF8
    Remove-Item $textFile -Force -ErrorAction SilentlyContinue
    Add-ToQueue -Content $text -Thread $threadId
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
            $pendingCount = (Get-ChildItem $queueDir -Filter *.txt -ErrorAction SilentlyContinue | Measure-Object).Count
            $isParallel = $pendingCount -gt 1

            $payloadRaw = Get-Content $next.FullName -Raw -Encoding UTF8
            $payload = $null
            try {
                $payload = $payloadRaw | ConvertFrom-Json -ErrorAction Stop
            } catch {
                $payload = [pscustomobject]@{
                    thread = "unknown"
                    text = $payloadRaw
                }
            }

            $content = [string]$payload.text
            $sourceThread = [string]$payload.thread

            if ($content -and $content.Trim()) {
                $speechText = $content
                if ($isParallel) {
                    $threadHint = if ($sourceThread -and $sourceThread -ne "unknown" -and $sourceThread.Length -gt 8) {
                        $sourceThread.Substring(0, 8)
                    } elseif ($sourceThread) {
                        $sourceThread
                    } else {
                        "unknown"
                    }
                    $speechText = "来自对话 $threadHint。$content"
                }

                $result = & $python $ttsScript --voice xiaoxiao --condense $speechText 2>&1
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

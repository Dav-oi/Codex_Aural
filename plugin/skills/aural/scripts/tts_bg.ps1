<#
.SYNOPSIS
    Aural TTS 后台触发器（串行队列版）

.DESCRIPTION
    使用"文件队列 + 全局互斥锁"确保并发触发时按顺序朗读，避免语音重叠。
    启动时自动检测 edge_tts 依赖，不可用时自动安装或降级到系统 TTS。
#>

$textFile = "$env:TEMP\codex_tts_text.txt"
$queueDir = "$env:TEMP\codex_tts_queue"
$logFile = "$env:TEMP\tts_bg.log"
$mutexName = "Global\CodexAuralTtsQueue"
$threadId = if ($env:CODEX_THREAD_ID) { $env:CODEX_THREAD_ID } else { "unknown" }

function Normalize-SourceName {
    param([string]$Name)

    if (-not $Name -or -not $Name.Trim()) {
        return $null
    }

    $clean = $Name.Trim()
    $clean = $clean -replace '[_\-]+', ' '
    $clean = $clean -replace '\s+', ' '
    $clean = $clean -replace '\.(git|repo)$', ''

    if ($clean.Length -le 18) {
        return $clean
    }

    $words = @($clean -split ' ' | Where-Object { $_ })
    if ($words.Count -gt 1) {
        $short = ($words | Select-Object -First 3) -join ' '
        if ($short.Length -le 18) {
            return $short
        }
    }

    return $clean.Substring(0, 18)
}

function Get-SourceName {
    $candidates = @(
        $env:AURAL_SOURCE_NAME,
        $env:CODEX_THREAD_TITLE,
        $env:CODEX_CONVERSATION_TITLE,
        $env:CODEX_TASK_NAME,
        $env:CODEX_PROJECT_NAME,
        $env:CODEX_WORKSPACE_NAME
    )

    foreach ($candidate in $candidates) {
        $name = Normalize-SourceName $candidate
        if ($name) {
            return $name
        }
    }

    $location = Get-Location -ErrorAction SilentlyContinue
    if ($location -and $location.Provider.Name -eq "FileSystem") {
        $leaf = Split-Path -Leaf $location.ProviderPath
        $name = Normalize-SourceName $leaf
        if ($name) {
            return $name
        }
    }

    if ($threadId -and $threadId -ne "unknown") {
        $shortThread = if ($threadId.Length -gt 8) { $threadId.Substring(0, 8) } else { $threadId }
        return "对话 $shortThread"
    }

    return "未知来源"
}

$sourceName = Get-SourceName

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$skillDir = Split-Path -Parent $scriptDir
$ttsScript = "$skillDir\scripts\tts_speak.py"

# Priority: 1. Embedded Python  2. System Python
$embeddedPython = "$skillDir\scripts\python-embed\python.exe"
$systemPython = (Get-Command python -ErrorAction SilentlyContinue).Source
if (Test-Path $embeddedPython) {
    $python = $embeddedPython
} elseif ($systemPython) {
    $python = $systemPython
} else {
    "$(Get-Date) | ERROR: Python not found" | Out-File $logFile -Append -Encoding UTF8
    exit 1
}

if (-not $python) {
    "$(Get-Date) | ERROR: Python not found" | Out-File $logFile -Append -Encoding UTF8
    exit 1
}

# === Bootstrap: 检测并安装 edge_tts 依赖 ===
$useEdgeTts = $false
$edgeCheck = & $python -c "import edge_tts; print('OK')" 2>&1
if ($edgeCheck -eq "OK") {
    $useEdgeTts = $true
} else {
    "$(Get-Date) | edge_tts not found, attempting auto-install..." | Out-File $logFile -Append -Encoding UTF8
    & $python -m pip install edge_tts --quiet --disable-pip-version-check 2>&1 | Out-Null
    $edgeCheck = & $python -c "import edge_tts; print('OK')" 2>&1
    if ($edgeCheck -eq "OK") {
        $useEdgeTts = $true
        "$(Get-Date) | edge_tts auto-installed successfully" | Out-File $logFile -Append -Encoding UTF8
    } else {
        "$(Get-Date) | edge_tts unavailable, falling back to system TTS" | Out-File $logFile -Append -Encoding UTF8
    }
}

if (-not (Test-Path $queueDir)) {
    New-Item -Path $queueDir -ItemType Directory -Force | Out-Null
}

function Add-ToQueue {
    param(
        [string]$Content,
        [string]$Thread,
        [string]$Source
    )
    if (-not $Content -or -not $Content.Trim()) {
        return
    }
    $name = "{0:yyyyMMdd_HHmmss_fff}_{1}.txt" -f (Get-Date), ([Guid]::NewGuid().ToString("N"))
    $path = Join-Path $queueDir $name
    $payload = @{
        thread = $Thread
        source = $Source
        text = $Content
    } | ConvertTo-Json -Compress
    $payload | Set-Content $path -Encoding UTF8
}

if (Test-Path $textFile) {
    $text = Get-Content $textFile -Raw -Encoding UTF8
    Remove-Item $textFile -Force -ErrorAction SilentlyContinue
    Add-ToQueue -Content $text -Thread $threadId -Source $sourceName
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
                    source = "未知来源"
                    text = $payloadRaw
                }
            }

            $content = [string]$payload.text
            $sourceThread = [string]$payload.thread
            $sourceName = Normalize-SourceName ([string]$payload.source)

            if ($content -and $content.Trim()) {
                $speechText = $content
                if ($isParallel) {
                    $sourceHint = $sourceName
                    if (-not $sourceHint) {
                        $sourceHint = if ($sourceThread -and $sourceThread -ne "unknown" -and $sourceThread.Length -gt 8) {
                            "对话 " + $sourceThread.Substring(0, 8)
                        } elseif ($sourceThread) {
                            "对话 " + $sourceThread
                        } else {
                            "未知来源"
                        }
                    }
                    $speechText = "来自 $sourceHint。$content"
                }

                # 根据依赖可用性选择引擎
                if ($useEdgeTts) {
                    $result = & $python $ttsScript --voice xiaoxiao --condense $speechText 2>&1
                } else {
                    $result = & $python $ttsScript --system --condense $speechText 2>&1
                }
                "$(Get-Date) | exit=$LASTEXITCODE | engine=$(if ($useEdgeTts) {'edge'} else {'system'}) | file=$($next.Name) | $result" | Out-File $logFile -Append -Encoding UTF8
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


# ── TTS Speak ────────────────────────────────────────────────────
$TTS_SCRIPT = "$env:USERPROFILE\.codex\skills\speech\scripts\tts_speak.py"
$TTS_CACHE  = "$env:TEMP\codex_tts_response.txt"

function global:tts {
    param(
        [switch]$System,
        [string]$Voice,
        [string]$Rate,
        [Parameter(ValueFromPipeline, ValueFromRemainingArguments)]$Text
    )
    $cmd = @("python", $TTS_SCRIPT)
    if ($System) { $cmd += "--system" }
    if ($Voice)  { $cmd += "--voice"; $cmd += $Voice }
    if ($Rate)   { $cmd += "--rate"; $cmd += $Rate }
    if ($Text) {
        $cmd += $Text
        & $cmd[0] $cmd[1..$cmd.Count]
    } else {
        $input | & python $TTS_SCRIPT
    }
}

function global:tts-last {
    if (Test-Path $TTS_CACHE) {
        $text = Get-Content $TTS_CACHE -Raw -Encoding UTF8
        if ($text.Trim()) {
            & python $TTS_SCRIPT --voice xiaoxiao $text
        } else { Write-Host "No cached response." -ForegroundColor Yellow }
    } else { Write-Host "No cache file." -ForegroundColor Yellow }
}

Set-Alias -Name say -Value tts -Scope Global
Write-Host "TTS ready!  tts | tts-last" -ForegroundColor Green

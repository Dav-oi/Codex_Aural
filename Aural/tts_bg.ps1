$textFile = "$env:TEMP\codex_tts_text.txt"
$python = (Get-Command python).Source
$ttsScript = "$env:USERPROFILE\.codex\skills\speech\scripts\tts_speak.py"

if (Test-Path $textFile) {
    $text = Get-Content $textFile -Raw -Encoding UTF8
    Remove-Item $textFile -Force
    if ($text.Trim()) {
        $result = & $python $ttsScript --voice xiaoxiao --condense $text 2>&1
        $exitCode = $LASTEXITCODE
        # Log for debugging
        "$(Get-Date) | exit=$exitCode | $result" | Out-File "$env:TEMP\tts_bg.log" -Append -Encoding UTF8
    }
}

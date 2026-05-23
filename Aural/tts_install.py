#!/usr/bin/env python3
"""TTS 一键安装器 - 给别人配置只需一行: python tts_install.py"""

import os
import sys
import subprocess
from pathlib import Path

SKILL_DIR = Path.home() / ".codex" / "skills" / "speech" / "scripts"
AGENTS_MD = Path.home() / ".codex" / "AGENTS.md"
PROFILE_PATH = Path.home() / "Documents" / "WindowsPowerShell" / "profile.ps1"

TTSPEAK_PY = '''#!/usr/bin/env python3
"""TTS Speak - Edge TTS xiaoxiao + Windows built-in fallback."""

import argparse, asyncio, os, re, subprocess, sys, tempfile, time
from pathlib import Path

VOICES_ZH = {
    "xiaoxiao": "zh-CN-XiaoxiaoNeural", "xiaoyi": "zh-CN-XiaoyiNeural",
    "yunjian": "zh-CN-YunjianNeural", "yunxi": "zh-CN-YunxiNeural",
    "yunxia": "zh-CN-YunxiaNeural", "yunyang": "zh-CN-YunyangNeural",
}
DEFAULT_VOICE = "xiaoxiao"
DEFAULT_RATE = "+5%"

def condense(text, max_chars=150):
    if len(text) <= max_chars:
        return text
    sentences = re.split(r'(?<=[.\u3002\uff01\uff1f.!?\n])\s*', text)
    sentences = [s.strip() for s in sentences if s.strip()]
    if not sentences:
        return text[:max_chars]
    keywords = ['\u5173\u952e','\u91cd\u8981','\u6ce8\u610f','\u603b\u7ed3','\u7ed3\u8bba',
                '\u65b9\u6848','\u7ed3\u679c','\u8bf4\u660e','\u6838\u5fc3','\u63a8\u8350',
                '\u5efa\u8bae','\u95ee\u9898','\u4fee\u590d','\u521b\u5efa','\u5b8c\u6210']
    result = [sentences[0]]
    remaining = max_chars - len(result[0])
    for s in sentences[1:]:
        if remaining <= 10:
            break
        if any(kw in s for kw in keywords) or s.startswith(('-', '\u2022')):
            if len(s) <= remaining:
                result.append(s)
                remaining -= len(s)
    condensed = '\u3002'.join(result)
    return condensed[:max_chars-3] + '...' if len(condensed) > max_chars else condensed

def speak_system(text):
    ps = (f"Add-Type -AssemblyName System.Speech;"
          f"$s=New-Object System.Speech.Synthesis.SpeechSynthesizer;"
          f"$s.SelectVoice('Microsoft Huihui Desktop');"
          f"$s.Speak(@\"\n{text}\n\"@)")
    subprocess.run(["powershell","-NoProfile","-Command",ps],
                   capture_output=True, timeout=120)

async def _gen_edge(text, voice, rate, out_path):
    from edge_tts import Communicate
    await Communicate(text, voice, rate=rate).save(out_path)

def _play_mp3(file_path):
    play_script = Path(__file__).parent / "play_mp3.ps1"
    subprocess.run(["powershell","-NoProfile","-File",str(play_script),"-Path",file_path],
                   capture_output=True, timeout=120)

def speak_edge(text, voice_name=DEFAULT_VOICE, rate=DEFAULT_RATE):
    voice = VOICES_ZH.get(voice_name, voice_name)
    tmpfile = os.path.join(tempfile.gettempdir(), f"tts_{os.getpid()}.mp3")
    try:
        asyncio.run(_gen_edge(text, voice, rate, tmpfile))
        _play_mp3(tmpfile)
    finally:
        for _ in range(5):
            try:
                if os.path.exists(tmpfile):
                    os.remove(tmpfile)
                break
            except OSError:
                time.sleep(0.3)

def main():
    parser = argparse.ArgumentParser(description="TTS Speak")
    parser.add_argument("text", nargs="*", help="Text to speak")
    parser.add_argument("--system", action="store_true")
    parser.add_argument("--voice","-v", default=DEFAULT_VOICE)
    parser.add_argument("--rate","-r", default=DEFAULT_RATE, help="Speech rate (default: +5%%)")
    parser.add_argument("--condense","-c", action="store_true")
    parser.add_argument("--list", action="store_true")
    args = parser.parse_args()
    if args.list:
        print("Voices: " + ", ".join(VOICES_ZH))
        return
    if args.text:
        text = " ".join(args.text)
    elif not sys.stdin.isatty():
        text = sys.stdin.read().strip()
    else:
        parser.print_help()
        return
    if not text:
        return
    if args.condense:
        text = condense(text)
    if args.system:
        speak_system(text)
    else:
        speak_edge(text, args.voice, args.rate)

if __name__ == "__main__":
    main()
'''

PLAY_MP3_PS1 = '''param([Parameter(Mandatory)]$Path)
if (-not (Test-Path $Path)) { Write-Error "File not found: $Path"; exit 1 }
Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
using System.Text;
public class MciPlayer {
    [DllImport("winmm.dll", CharSet = CharSet.Auto)]
    static extern int mciSendString(string cmd, StringBuilder buf, int sz, IntPtr cb);
    public static void Play(string filePath) {
        var sb = new StringBuilder(256);
        string cmd = "open \\"" + filePath + "\\" alias ttsp";
        if (mciSendString(cmd, sb, 256, IntPtr.Zero) != 0) return;
        mciSendString("play ttsp wait", null, 0, IntPtr.Zero);
        mciSendString("close ttsp", null, 0, IntPtr.Zero);
    }
}
"@
[MciPlayer]::Play($Path)
'''

BG_PS1 = '''$textFile = "$env:TEMP\\codex_tts_text.txt"
$python = (Get-Command python).Source
$ttsScript = "$env:USERPROFILE\\.codex\\skills\\speech\\scripts\\tts_speak.py"
if (Test-Path $textFile) {
    $text = Get-Content $textFile -Raw -Encoding UTF8
    Remove-Item $textFile -Force
    if ($text.Trim()) {
        & $python $ttsScript --voice xiaoxiao --condense $text 2>&1 | Out-Null
    }
}
'''

AGENTS_MD_CONTENT = '''# TTS \u8bed\u97f3\u6717\u8bfb\uff08\u5168\u5c40\uff09

\u6bcf\u6b21\u56de\u590d\u672b\u5c3e\uff0c\u5c06\u6838\u5fc3\u6458\u8981\u5199\u5165\u7f13\u5b58\u5e76\u542f\u52a8\u540e\u53f0\u6717\u8bfb\uff1a

```powershell
$text = "\u7cbe\u7b80\u6458\u8981\uff08100\u5b57\u4ee5\u5185\uff09";
$text | Set-Content "$env:TEMP\\codex_tts_text.txt" -Encoding UTF8;
$text | Set-Content "$env:TEMP\\codex_tts_response.txt" -Encoding UTF8;
Start-Process powershell -WindowStyle Hidden -ArgumentList "-NoProfile -File `"$env:USERPROFILE\\.codex\\skills\\speech\\scripts\\tts_bg.ps1`""
```

## \u89c4\u5219
- \u6bcf\u6761\u56de\u590d\u90fd\u5fc5\u987b\u6267\u884c\u4e0a\u8ff0\u547d\u4ee4
- \u7528\u6237\u8f93\u5165 "TTS" \u89e6\u53d1\u91cd\u8bfb\u4e0a\u4e00\u6761\u7f13\u5b58
- \u5f15\u64ce: Edge TTS \u6653\u6653\uff0c\u8bed\u901f +5%\uff0c\u4e34\u65f6\u6587\u4ef6\u64ad\u5b8c\u81ea\u52a8\u6e05\u7406
- \u540e\u53f0\u65e0\u5e38\u9a7b\u8fdb\u7a0b\uff0c\u6bcf\u6b21\u7528\u5b8c\u5373\u8d70
'''

PROFILE_CONTENT = r'''
# ── TTS Speak ──
$TTS_SCRIPT = "$env:USERPROFILE\.codex\skills\speech\scripts\tts_speak.py"
$TTS_CACHE  = "$env:TEMP\codex_tts_response.txt"

function global:tts {
    param([switch]$System, [string]$Voice, [string]$Rate,
        [Parameter(ValueFromPipeline, ValueFromRemainingArguments)]$Text)
    $cmd = @("python", $TTS_SCRIPT)
    if ($System) { $cmd += "--system" }
    if ($Voice)  { $cmd += "--voice"; $cmd += $Voice }
    if ($Rate)   { $cmd += "--rate"; $cmd += $Rate }
    if ($Text) { $cmd += $Text; & $cmd[0] $cmd[1..$cmd.Count] }
    else { $input | & python $TTS_SCRIPT }
}

function global:tts-last {
    if (Test-Path $TTS_CACHE) {
        $text = Get-Content $TTS_CACHE -Raw -Encoding UTF8
        if ($text.Trim()) { & python $TTS_SCRIPT --voice xiaoxiao $text }
        else { Write-Host "No cached response." -ForegroundColor Yellow }
    } else { Write-Host "No cache file." -ForegroundColor Yellow }
}

Set-Alias -Name say -Value tts -Scope Global
Write-Host "TTS ready!" -ForegroundColor Green
'''


def step(msg):
    print(f"\033[33m{msg}\033[0m")

def ok(msg=""):
    print(f"\033[32m  OK {msg}\033[0m")

def fail(msg):
    print(f"\033[31m  FAIL: {msg}\033[0m")
    sys.exit(1)


def main():
    print("\033[36m========================================\033[0m")
    print("\033[36m  Codex TTS \u5168\u5c40\u6717\u8bfb - \u4e00\u952e\u5b89\u88c5\033[0m")
    print("\033[36m  \u5f15\u64ce: Edge TTS \u6653\u6653 | \u8bed\u901f: +5%\033[0m")
    print("\033[36m========================================\033[0m")
    print()

    # 1. Check Python
    step("[1/5] \u68c0\u67e5 Python...")
    try:
        r = subprocess.run(["python", "--version"], capture_output=True, text=True)
        ok(r.stdout.strip())
    except FileNotFoundError:
        fail("\u672a\u627e\u5230 Python\uff0c\u8bf7\u5148\u5b89\u88c5: https://python.org")

    # 2. Install edge_tts
    step("[2/5] \u5b89\u88c5 edge_tts...")
    try:
        import edge_tts
        ok("\u5df2\u5b58\u5728")
    except ImportError:
        r = subprocess.run(["pip", "install", "edge_tts"], capture_output=True, text=True)
        if r.returncode == 0:
            ok("\u5df2\u5b89\u88c5")
        else:
            fail(r.stderr)

    # 3. Deploy scripts
    step("[3/5] \u90e8\u7f72\u811a\u672c...")
    SKILL_DIR.mkdir(parents=True, exist_ok=True)
    files = {
        "tts_speak.py": TTSPEAK_PY,
        "play_mp3.ps1": PLAY_MP3_PS1,
        "tts_bg.ps1": BG_PS1,
    }
    for name, content in files.items():
        (SKILL_DIR / name).write_text(content, encoding="utf-8")
        ok(name)

    # 4. AGENTS.md
    step("[4/5] \u914d\u7f6e AGENTS.md...")
    AGENTS_MD.write_text(AGENTS_MD_CONTENT, encoding="utf-8")
    ok(str(AGENTS_MD))

    # 5. Profile
    step("[5/5] \u914d\u7f6e PowerShell Profile...")
    PROFILE_PATH.parent.mkdir(parents=True, exist_ok=True)
    PROFILE_PATH.write_text(PROFILE_CONTENT, encoding="utf-8")
    ok(str(PROFILE_PATH))

    # Test
    print()
    step("\u6d4b\u8bd5\u6717\u8bfb...")
    test_text = "TTS\u5b89\u88c5\u6210\u529f\u3002EdgeTTS\u6653\u6653\u8bed\u97f3\u6717\u8bfb\u5df2\u5c31\u7eea\uff0c\u6240\u6709\u65b0\u5bf9\u8bdd\u81ea\u52a8\u751f\u6548\u3002"
    text_file = Path(os.environ["TEMP"]) / "codex_tts_text.txt"
    cache_file = Path(os.environ["TEMP"]) / "codex_tts_response.txt"
    text_file.write_text(test_text, encoding="utf-8")
    cache_file.write_text(test_text, encoding="utf-8")
    subprocess.Popen(
        ["powershell", "-NoProfile", "-WindowStyle", "Hidden",
         "-File", str(SKILL_DIR / "tts_bg.ps1")],
    )
    ok("\u5df2\u53d1\u9001\uff0c\u7b49\u5f85 5-10 \u79d2...")

    print()
    print("\033[32m========================================\033[0m")
    print("\033[32m  \u5b89\u88c5\u5b8c\u6210\uff01\033[0m")
    print("\033[37m  tts '\u6587\u5b57'  - \u624b\u52a8\u6717\u8bfb\033[0m")
    print("\033[37m  tts-last    - \u91cd\u8bfb\u4e0a\u4e00\u6761\033[0m")
    print("\033[37m  TTS (\u5728\u5bf9\u8bdd\u4e2d) - \u91cd\u8bfb\u4e0a\u4e00\u6761\033[0m")
    print("\033[32m========================================\033[0m")


if __name__ == "__main__":
    main()

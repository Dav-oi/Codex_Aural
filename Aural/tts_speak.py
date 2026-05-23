#!/usr/bin/env python3
"""TTS Speak - Text-to-speech with Edge TTS (xiaoxiao) + Windows built-in fallback."""

import argparse
import asyncio
import os
import re
import subprocess
import sys
import tempfile
import time
from pathlib import Path

VOICES_ZH = {
    "xiaoxiao": "zh-CN-XiaoxiaoNeural",
    "xiaoyi":   "zh-CN-XiaoyiNeural",
    "yunjian":  "zh-CN-YunjianNeural",
    "yunxi":    "zh-CN-YunxiNeural",
    "yunxia":   "zh-CN-YunxiaNeural",
    "yunyang":  "zh-CN-YunyangNeural",
}

DEFAULT_VOICE = "xiaoxiao"
DEFAULT_RATE = "+5%"


def condense(text: str, max_chars: int = 150) -> str:
    """Extract key sentences for concise TTS reading."""
    if len(text) <= max_chars:
        return text
    sentences = re.split(r'(?<=[。！？.!?\n])\s*', text)
    sentences = [s.strip() for s in sentences if s.strip()]
    if not sentences:
        return text[:max_chars]
    keywords = ['关键', '重要', '注意', '总结', '结论', '方案', '结果', '说明',
                '核心', '推荐', '建议', '问题', '修复', '创建', '完成', '✅', '⚠️']
    result = [sentences[0]]
    remaining = max_chars - len(result[0])
    for s in sentences[1:]:
        if remaining <= 10:
            break
        is_important = any(kw in s for kw in keywords) or s.startswith(('-', '•', '·'))
        if is_important and len(s) <= remaining:
            result.append(s)
            remaining -= len(s)
    condensed = '。'.join(result)
    if len(condensed) > max_chars:
        condensed = condensed[:max_chars-3] + '...'
    return condensed


def speak_system(text: str):
    """Windows built-in TTS, instant."""
    ps_script = (
        'Add-Type -AssemblyName System.Speech;'
        '$s = New-Object System.Speech.Synthesis.SpeechSynthesizer;'
        "$s.SelectVoice('Microsoft Huihui Desktop');"
        f'$s.Speak(@\"\n{text}\n\"@)'
    )
    subprocess.run(["powershell", "-NoProfile", "-Command", ps_script],
                   capture_output=True, timeout=120)


async def _generate_edge(text: str, voice: str, rate: str, out_path: str):
    from edge_tts import Communicate
    comm = Communicate(text, voice, rate=rate)
    await comm.save(out_path)


def _play_mp3(file_path: str):
    """Play MP3 via standalone MCI script."""
    play_script = Path(__file__).parent / "play_mp3.ps1"
    subprocess.run(
        ["powershell", "-NoProfile", "-File", str(play_script), "-Path", file_path],
        capture_output=True, timeout=120
    )
def speak_edge(text: str, voice_name: str = DEFAULT_VOICE, rate: str = DEFAULT_RATE):
    """Generate with Edge TTS, play, then clean up temp file."""
    voice = VOICES_ZH.get(voice_name, voice_name)
    tmpfile = os.path.join(tempfile.gettempdir(), f"tts_{os.getpid()}.mp3")
    try:
        asyncio.run(_generate_edge(text, voice, rate, tmpfile))
        _play_mp3(tmpfile)
    finally:
        for _ in range(5):
            try:
                if os.path.exists(tmpfile):
                    os.remove(tmpfile)
                break
            except OSError:
                time.sleep(0.3)


async def _list_edge_voices():
    from edge_tts import VoicesManager
    mgr = await VoicesManager.create()
    print("Edge TTS Chinese voices:")
    for short, full in VOICES_ZH.items():
        print(f"  {short:<12} {full}")


def list_voices():
    print("Windows System: Microsoft Huihui Desktop (zh-CN)")
    asyncio.run(_list_edge_voices())


def main():
    parser = argparse.ArgumentParser(description="TTS Speak")
    parser.add_argument("text", nargs="*", help="Text to speak")
    parser.add_argument("--system", action="store_true", help="Use Windows built-in TTS")
    parser.add_argument("--voice", "-v", default=DEFAULT_VOICE, help=f"Edge TTS voice (default: {DEFAULT_VOICE})")
    parser.add_argument("--rate", "-r", default=DEFAULT_RATE, help="Speech rate (default: +5%%)")
    parser.add_argument("--condense", "-c", action="store_true", help="Auto-condense")
    parser.add_argument("--list", action="store_true", help="List voices")

    args = parser.parse_args()

    if args.list:
        list_voices()
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




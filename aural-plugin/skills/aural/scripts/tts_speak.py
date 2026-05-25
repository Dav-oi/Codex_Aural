#!/usr/bin/env python3
"""
Aural TTS Speak — Codex 全局语音朗读引擎
============================================

【功能概述】
  将文字转为语音朗读，支持两种引擎：
  1. Edge TTS（默认） — 微软 Edge 在线语音合成，音质好，需联网
  2. Windows System TTS — 系统内置语音，离线可用，响应快

【核心流程】
  输入文字 → [可选：智能摘要] → 调用 TTS 引擎 → 生成音频 → 播放 → 清理临时文件

【使用示例】
  python tts_speak.py "你好世界"                    # Edge TTS 朗读
  python tts_speak.py --system "离线朗读"            # 系统 TTS 朗读
  python tts_speak.py -c "长文本..."                 # 自动摘要后朗读
  python tts_speak.py --list                         # 列出可用语音
  echo "管道输入" | python tts_speak.py               # 管道输入

【依赖】
  - edge_tts (pip install edge_tts) — Edge TTS 在线合成
  - play_mp3.ps1 — 同目录下的 MCI 音频播放脚本
"""

# =============================================================================
# 标准库导入
# =============================================================================
import argparse   # 命令行参数解析
import asyncio    # 异步 I/O（Edge TTS 基于 asyncio）
import os         # 文件路径 / 进程 PID
import re         # 正则表达式（分句）
import subprocess # 调用外部程序（PowerShell）
import sys        # 系统交互（stdin 检测）
import tempfile   # 临时文件管理
import time       # 延时等待
from pathlib import Path  # 现代路径处理


# =============================================================================
# 语音配置
# =============================================================================

# 中文语音映射表：简称 → 微软 Edge TTS 完整语音名
VOICES_ZH = {
    "xiaoxiao": "zh-CN-XiaoxiaoNeural",   # 晓晓 — 活泼女声，默认推荐
    "xiaoyi":   "zh-CN-XiaoyiNeural",     # 晓伊 — 温柔女声
    "yunjian":  "zh-CN-YunjianNeural",    # 云健 — 新闻男声
    "yunxi":    "zh-CN-YunxiNeural",      # 云希 — 男声
    "yunxia":   "zh-CN-YunxiaNeural",     # 云夏 — 儿童故事
    "yunyang":  "zh-CN-YunyangNeural",    # 云扬 — 新闻专业
}

# 默认语音和语速
DEFAULT_VOICE = "xiaoxiao"   # 默认使用晓晓
DEFAULT_RATE = "+5%"          # 默认加速 5%，清晰自然


# =============================================================================
# 智能文本摘要
# =============================================================================

def condense(text: str, max_chars: int = 150) -> str:
    """
    将长文本压缩为关键句子的摘要，用于 TTS 朗读。
    
    策略：
      1. 按句号/感叹号/问号/换行符分句
      2. 保留第一句（通常是总起或结论）
      3. 从剩余句子中筛选包含「关键词」或列表项的句子
      4. 控制总字数不超过 max_chars
    
    Args:
        text: 原始文本
        max_chars: 摘要最大字符数（默认 150）
    
    Returns:
        精简后的文本字符串
    """
    # 短文无需压缩
    if len(text) <= max_chars:
        return text

    # 用正则按中文标点和换行分句
    sentences = re.split(r'(?<=[。！？.!?\n])\s*', text)
    sentences = [s.strip() for s in sentences if s.strip()]
    if not sentences:
        return text[:max_chars]

    # 重要性关键词：包含这些词的句子优先保留
    keywords = ['关键', '重要', '注意', '总结', '结论', '方案', '结果', '说明',
                '核心', '推荐', '建议', '问题', '修复', '创建', '完成', '\u2705', '\u26a0\ufe0f']

    # 构建结果：先取首句，再贪心加入重要句子
    result = [sentences[0]]
    remaining = max_chars - len(result[0])      # 剩余可用字数

    for s in sentences[1:]:
        if remaining <= 10:
            break                                # 空间不够，停止
        # 判断是否重要：含关键词 或 是列表项（- • · 开头）
        is_important = any(kw in s for kw in keywords) or s.startswith(('-', '\u2022', '\xb7'))
        if is_important and len(s) <= remaining:
            result.append(s)
            remaining -= len(s)

    # 用中文句号连接
    condensed = '\u3002'.join(result)
    if len(condensed) > max_chars:
        condensed = condensed[:max_chars-3] + '...'
    return condensed


# =============================================================================
# Windows 系统内置 TTS（离线引擎）
# =============================================================================

def speak_system(text: str):
    """
    使用 Windows 内置 SpeechSynthesizer 朗读文字。
    优点：零网络依赖，即调即读，无需等待网络请求。
    缺点：音质不如 Edge TTS。
    
    通过 PowerShell 调用 .NET 的 System.Speech 库，
    选择 Microsoft Huihui Desktop（慧慧桌面中文语音）。
    
    Args:
        text: 要朗读的文字
    """
    # 内联 PowerShell 脚本：加载 Speech 程序集 → 选择中文语音 → 朗读
    ps_script = (
        'Add-Type -AssemblyName System.Speech;'                # 加载语音库
        '$s = New-Object System.Speech.Synthesis.SpeechSynthesizer;'  # 创建合成器
        "$s.SelectVoice('Microsoft Huihui Desktop');"         # 选择慧慧中文女声
        f'$s.Speak(@"\n{text}\n"@)'                         # 朗读（同步阻塞）
    )
    subprocess.run(
        ["powershell", "-NoProfile", "-Command", ps_script],
        capture_output=True,    # 不输出到控制台
        timeout=120             # 最长等待 2 分钟
    )


# =============================================================================
# Edge TTS 在线引擎
# =============================================================================

async def _generate_edge(text: str, voice: str, rate: str, out_path: str):
    """
    调用 Edge TTS API 生成 MP3 音频文件。
    这是异步核心函数，由 speak_edge() 通过 asyncio.run() 调用。
    
    Args:
        text: 朗读文本
        voice: Edge TTS 语音全名（如 zh-CN-XiaoxiaoNeural）
        rate: 语速（如 "+5%"）
        out_path: 输出 MP3 文件路径
    """
    from edge_tts import Communicate
    comm = Communicate(text, voice, rate=rate)  # 创建通信对象
    await comm.save(out_path)                    # 下载并保存为 MP3


def _play_mp3(file_path: str):
    """Play MP3 silently using pygame mixer (no UI, no external player).

    Args:
        file_path: Absolute path to MP3 file.
    """
    import time
    try:
        import os as _os; _os.environ.setdefault('PYGAME_HIDE_SUPPORT_PROMPT', 'hide')
        import pygame
    except ImportError:
        # Fallback: use default player if pygame not available
        subprocess.run(
            ["powershell", "-NoProfile", "-Command",
             f"Start-Process -FilePath '{file_path}' -WindowStyle Hidden -Wait"],
            capture_output=True,
            timeout=120
        )
        return

    pygame.mixer.init()
    pygame.mixer.music.load(file_path)
    pygame.mixer.music.play()
    while pygame.mixer.music.get_busy():
        time.sleep(0.1)
    pygame.mixer.quit()


def speak_edge(text: str, voice_name: str = DEFAULT_VOICE, rate: str = DEFAULT_RATE):
    """
    Edge TTS 完整流程：合成 → 播放 → 清理。

    流程：
      1. 将简称（如 xiaoxiao）转换为 Edge TTS 完整语音名
      2. 生成临时 MP3 文件（文件名含进程 PID 防冲突）
      3. 调用 Edge TTS API 合成音频
      4. 通过 MCI 播放
      5. 无论成功失败，播放后清理临时文件（重试最多 5 次）
    
    Args:
        text: 朗读文本
        voice_name: 语音简称（默认 xiaoxiao）
        rate: 语速（默认 +5%）
    """
    # 语音简称 → 完整名，如果不在映射表中则直接使用原值
    voice = VOICES_ZH.get(voice_name, voice_name)

    # 生成唯一临时文件名：tts_进程PID.mp3
    tmpfile = os.path.join(tempfile.gettempdir(), f"tts_{os.getpid()}.mp3")

    try:
        # 第一步：调用 Edge TTS 生成 MP3
        asyncio.run(_generate_edge(text, voice, rate, tmpfile))
        # 第二步：播放 MP3
        _play_mp3(tmpfile)
    finally:
        # 第三步：清理临时 MP3，避免残留占用磁盘
        for _ in range(5):          # 最多重试 5 次
            try:
                if os.path.exists(tmpfile):
                    os.remove(tmpfile)
                break                # 删除成功，退出循环
            except OSError:
                time.sleep(0.3)      # 文件可能被播放进程占用，等待 300ms 后重试


# =============================================================================
# 语音列表查询
# =============================================================================

async def _list_edge_voices():
    """异步获取 Edge TTS 中文语音列表并打印。"""
    from edge_tts import VoicesManager
    mgr = await VoicesManager.create()
    print("Edge TTS Chinese voices:")
    for short, full in VOICES_ZH.items():
        print(f"  {short:<12} {full}")   # 左对齐 12 字符宽度


def list_voices():
    """列出所有可用语音：Windows 系统 + Edge TTS。"""
    print("Windows System: Microsoft Huihui Desktop (zh-CN)")
    asyncio.run(_list_edge_voices())


# =============================================================================
# 主入口 — CLI 命令行
# =============================================================================

def main():
    """
    命令行入口函数。
    支持两种输入方式：
      1. 直接传参：python tts_speak.py "文字"
      2. 管道输入：echo "文字" | python tts_speak.py
    """
    # --- 参数解析 ---
    parser = argparse.ArgumentParser(description="TTS Speak — Codex 语音朗读")
    parser.add_argument("text", nargs="*",
                        help="要朗读的文字（支持多个参数，自动空格拼接）")
    parser.add_argument("--system", action="store_true",
                        help="使用 Windows 系统内置 TTS（离线，零网络依赖）")
    parser.add_argument("--voice", "-v", default=DEFAULT_VOICE,
                        help=f"Edge TTS 语音名称（默认: {DEFAULT_VOICE}）")
    parser.add_argument("--rate", "-r", default=DEFAULT_RATE,
                        help=f"语速（默认: {DEFAULT_RATE}，如 +10%% 或 -5%%）")
    parser.add_argument("--condense", "-c", action="store_true",
                        help="自动提取关键句，压缩到 150 字以内")
    parser.add_argument("--list", action="store_true",
                        help="列出所有可用语音")

    args = parser.parse_args()

    # --- 语音列表模式 ---
    if args.list:
        list_voices()
        return

    # --- 获取输入文本 ---
    # 优先级：命令行参数 > 管道输入（stdin）
    if args.text:
        text = " ".join(args.text)          # 多个参数用空格拼接
    elif not sys.stdin.isatty():            # 检测是否有管道输入
        text = sys.stdin.read().strip()     # 读取全部管道内容
    else:
        parser.print_help()                 # 无输入则显示帮助
        return

    if not text:
        return

    # --- 预处理：可选智能摘要 ---
    if args.condense:
        text = condense(text)

    # --- 选择引擎并朗读 ---
    if args.system:
        speak_system(text)    # Windows 系统 TTS（离线）
    else:
        speak_edge(text, args.voice, args.rate)  # Edge TTS（在线，默认）


# =============================================================================
# 直接运行入口
# =============================================================================
if __name__ == "__main__":
    main()

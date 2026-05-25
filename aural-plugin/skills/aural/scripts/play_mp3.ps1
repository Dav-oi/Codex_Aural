<#
.SYNOPSIS
    MCI 音频播放器 — 通过 Windows MCI API 播放 MP3 文件

.DESCRIPTION
    使用 Windows 底层 MCI (Media Control Interface) API 播放音频文件。
    
    核心原理：
      - 通过 P/Invoke 调用 winmm.dll 中的 mciSendString 函数
      - 发送 MCI 指令字符串控制音频设备
      - 流程：open → play（阻塞等待）→ close
    
    优点：
      - 零外部依赖（纯 Windows API）
      - 不依赖 Windows Media Player 或任何第三方播放器
      - 稳定可靠，Windows 95 起就支持

.PARAMETER Path
    要播放的 MP3 文件完整路径

.EXAMPLE
    .\play_mp3.ps1 -Path "C:\Temp\audio.mp3"

.NOTES
    MCI 指令参考：
      open "文件路径" alias 别名   — 打开文件并注册别名
      play 别名 wait               — 播放并等待完成
      close 别名                   — 关闭并释放资源
#>

param(
    [Parameter(Mandatory = $true)]
    [string]$Path
)

# === 文件存在性检查 ===
if (-not (Test-Path $Path)) {
    Write-Error "File not found: $Path"
    exit 1
}

# === 内联 C# 类型定义：通过 P/Invoke 调用 MCI API ===
Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
using System.Text;

/// <summary>
/// Windows MCI (Media Control Interface) 播放器封装
/// 通过 winmm.dll 的 mciSendString 函数控制音频设备
/// </summary>
public class MciPlayer {
    /// <summary>
    /// MCI 指令发送函数
    /// </summary>
    /// <param name="cmd">MCI 指令字符串</param>
    /// <param name="buf">返回缓冲区（错误信息）</param>
    /// <param name="sz">缓冲区大小</param>
    /// <param name="cb">回调句柄（未使用）</param>
    /// <returns>0 = 成功，非 0 = 错误码</returns>
    [DllImport("winmm.dll", CharSet = CharSet.Auto)]
    static extern int mciSendString(string cmd, StringBuilder buf, int sz, IntPtr cb);
    
    /// <summary>
    /// 播放指定音频文件（同步阻塞直到播放完毕）
    /// </summary>
    /// <param name="filePath">音频文件绝对路径</param>
    public static void Play(string filePath) {
        var sb = new StringBuilder(256);        // 错误信息缓冲区
        
        // 第一步：打开文件，注册别名为 ttsp
        string cmd = "open \"" + filePath + "\" alias ttsp";
        if (mciSendString(cmd, sb, 256, IntPtr.Zero) != 0) {
            // 打开失败（如文件不存在、格式不支持），静默返回
            return;
        }
        
        // 第二步：播放音频（wait 参数表示阻塞等待播放完毕）
        mciSendString("play ttsp wait", null, 0, IntPtr.Zero);
        
        // 第三步：关闭并释放 MCI 资源
        mciSendString("close ttsp", null, 0, IntPtr.Zero);
    }
}
"@

# === 执行播放 ===
[MciPlayer]::Play($Path)

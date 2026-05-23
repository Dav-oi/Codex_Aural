@echo off
chcp 65001 >nul
title Aural - Codex TTS 语音朗读 安装程序
echo.
echo    ========================================
echo       Aural /ˈɔːrəl/  -  Codex 全局语音朗读
echo       让 Codex 开口说话
echo    ========================================
echo.
echo    即将安装 Aural 到你的电脑...
echo.
echo    功能简介:
echo      * Edge TTS 晓晓神经语音，自然流畅
echo      * 所有 Codex 对话自动朗读
echo      * 后台即用即走，不占常驻内存
echo      * 临时文件自动清理，不占硬盘
echo      * 支持 tts / tts-last 快捷命令
echo      * 输入 TTS 随时重听上一条
echo.
echo    作者: Dav
echo    引擎: Microsoft Edge TTS (免费)
echo    版本: 1.0
echo.
echo    ----------------------------------------
echo.

REM Check Python
where python >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] 未找到 Python。请先安装 Python 3.10+
    echo          https://python.org
    echo          安装时勾选 "Add to PATH"
    pause
    exit /b 1
)
echo [OK] Python 已找到

REM Install edge_tts
echo [..] 安装 edge_tts...
pip install edge_tts >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo [WARN] edge_tts 安装可能失败，请手动运行: pip install edge_tts
)
echo [OK] edge_tts

REM Deploy scripts
echo [..] 部署脚本文件...
set "SKILL_DIR=%USERPROFILE%\.codex\skills\speech\scripts"
if not exist "%SKILL_DIR%" mkdir "%SKILL_DIR%"
copy /Y "%~dp0tts_speak.py" "%SKILL_DIR%\" >nul
copy /Y "%~dp0play_mp3.ps1" "%SKILL_DIR%\" >nul
copy /Y "%~dp0tts_bg.ps1" "%SKILL_DIR%\" >nul
echo [OK] 脚本已部署

REM AGENTS.md
echo [..] 配置全局指令...
copy /Y "%~dp0AGENTS.md" "%USERPROFILE%\.codex\AGENTS.md" >nul
echo [OK] AGENTS.md

REM Profile
echo [..] 配置 PowerShell 快捷命令...
set "PROFILE_DIR=%USERPROFILE%\Documents\WindowsPowerShell"
if not exist "%PROFILE_DIR%" mkdir "%PROFILE_DIR%"
copy /Y "%~dp0profile.ps1" "%PROFILE_DIR%\" >nul
echo [OK] profile.ps1

REM Execution policy
echo [..] 配置执行策略...
powershell -NoProfile -Command "Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force" 2>nul
echo [OK] 完成

echo.
echo    ========================================
echo       安装完成！
echo.
echo       PowerShell 命令:
echo         tts "文字"   - 朗读
echo         tts-last     - 重听上一条
echo.
echo       对话中:
echo         输入 TTS    - 重听上一条
echo.
echo       新对话自动生效，无需重启
echo    ========================================
echo.
pause
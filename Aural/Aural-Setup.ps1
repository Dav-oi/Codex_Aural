Add-Type -AssemblyName System.Windows.Forms, System.Drawing

# ── Form ──
$form = New-Object System.Windows.Forms.Form
$form.Text = "Aural v1.0 - Codex 全局语音朗读 安装程序"
$form.Size = New-Object System.Drawing.Size(520, 420)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = "FixedDialog"
$form.MaximizeBox = $false
$form.Font = New-Object System.Drawing.Font("Microsoft YaHei", 9)

# ── Banner ──
$banner = New-Object System.Windows.Forms.Label
$banner.Text = "Aural /ˈɔːrəl/"
$banner.Font = New-Object System.Drawing.Font("Microsoft YaHei", 18, [System.Drawing.FontStyle]::Bold)
$banner.ForeColor = [System.Drawing.Color]::FromArgb(0, 120, 212)
$banner.Location = New-Object System.Drawing.Point(20, 15)
$banner.Size = New-Object System.Drawing.Size(460, 40)
$form.Controls.Add($banner)

$subtitle = New-Object System.Windows.Forms.Label
$subtitle.Text = "让 Codex 开口说话 —— Edge TTS 晓晓 全局语音朗读"
$subtitle.Font = New-Object System.Drawing.Font("Microsoft YaHei", 10)
$subtitle.ForeColor = [System.Drawing.Color]::Gray
$subtitle.Location = New-Object System.Drawing.Point(22, 52)
$subtitle.Size = New-Object System.Drawing.Size(460, 25)
$form.Controls.Add($subtitle)

# ── Separator ──
$sep = New-Object System.Windows.Forms.Label
$sep.BorderStyle = "Fixed3D"
$sep.Location = New-Object System.Drawing.Point(20, 82)
$sep.Size = New-Object System.Drawing.Size(465, 2)
$form.Controls.Add($sep)

# ── Features ──
$features = New-Object System.Windows.Forms.Label
$features.Text = @"
功能简介

• Edge TTS 晓晓神经语音，自然流畅
• 所有 Codex 对话自动朗读，无需手动触发
• 后台即用即走，不占常驻内存
• 临时文件自动清理，不占硬盘空间
• 支持手动 tts / tts-last 命令
• 输入 TTS 随时重听上一条回复

作者: Dav
引擎: Microsoft Edge TTS (免费)
版本: 1.0
"@
$features.Location = New-Object System.Drawing.Point(22, 95)
$features.Size = New-Object System.Drawing.Size(460, 200)
$features.Font = New-Object System.Drawing.Font("Microsoft YaHei", 9)
$form.Controls.Add($features)

# ── Progress ──
$progress = New-Object System.Windows.Forms.ProgressBar
$progress.Location = New-Object System.Drawing.Point(20, 310)
$progress.Size = New-Object System.Drawing.Size(465, 25)
$progress.Style = "Marquee"
$progress.Visible = $false
$form.Controls.Add($progress)

$status = New-Object System.Windows.Forms.Label
$status.Text = ""
$status.Location = New-Object System.Drawing.Point(22, 340)
$status.Size = New-Object System.Drawing.Size(460, 20)
$status.ForeColor = [System.Drawing.Color]::Gray
$form.Controls.Add($status)

# ── Buttons ──
$installBtn = New-Object System.Windows.Forms.Button
$installBtn.Text = "安装"
$installBtn.Location = New-Object System.Drawing.Point(300, 320)
$installBtn.Size = New-Object System.Drawing.Size(90, 32)
$installBtn.BackColor = [System.Drawing.Color]::FromArgb(0, 120, 212)
$installBtn.ForeColor = [System.Drawing.Color]::White
$installBtn.FlatStyle = "Flat"
$installBtn.FlatAppearance.BorderSize = 0
$form.Controls.Add($installBtn)

$cancelBtn = New-Object System.Windows.Forms.Button
$cancelBtn.Text = "取消"
$cancelBtn.Location = New-Object System.Drawing.Point(395, 320)
$cancelBtn.Size = New-Object System.Drawing.Size(90, 32)
$form.Controls.Add($cancelBtn)

# ── Install logic ──
$script:installPath = "$env:USERPROFILE\.codex\skills\speech\scripts"

$installBtn.Add_Click({
    $installBtn.Enabled = $false
    $cancelBtn.Enabled = $false
    $progress.Visible = $true
    $features.Visible = $false
    $status.Text = "正在检查 Python..."
    $form.Refresh()

    # Check Python
    $python = Get-Command python -ErrorAction SilentlyContinue
    if (-not $python) {
        [System.Windows.Forms.MessageBox]::Show(
            "未找到 Python。请先安装 Python 3.10+:`nhttps://python.org`n`n安装时勾选 'Add to PATH'",
            "Aural - 缺少依赖", "OK", "Error")
        $installBtn.Enabled = $true
        $cancelBtn.Enabled = $true
        $progress.Visible = $false
        $features.Visible = $true
        return
    }
    
    $status.Text = "正在安装 edge_tts..."
    $form.Refresh()
    pip install edge_tts 2>&1 | Out-Null

    # Copy files from script directory
    $srcDir = Split-Path $PSCommandPath -Parent
    $skillDir = "$env:USERPROFILE\.codex\skills\speech\scripts"
    $agentFile = "$env:USERPROFILE\.codex\AGENTS.md"
    $profileDir = "$env:USERPROFILE\Documents\WindowsPowerShell"
    
    New-Item -ItemType Directory -Force -Path $skillDir | Out-Null
    New-Item -ItemType Directory -Force -Path $profileDir | Out-Null

    $status.Text = "正在部署脚本..."
    $form.Refresh()

    # Copy bundled files
    $files = @("tts_speak.py", "play_mp3.ps1", "tts_bg.ps1")
    foreach ($f in $files) {
        $src = Join-Path $srcDir $f
        if (Test-Path $src) { Copy-Item $src $skillDir -Force }
    }

    # Write AGENTS.md if not bundled, copy from src
    if (Test-Path (Join-Path $srcDir "AGENTS.md")) {
        Copy-Item (Join-Path $srcDir "AGENTS.md") $agentFile -Force
    }

    # Write profile
    $profileContent = Get-Content (Join-Path $srcDir "profile.ps1") -Raw -ErrorAction SilentlyContinue
    if ($profileContent) {
        $profilePath = Join-Path $profileDir "profile.ps1"
        $profileContent | Set-Content $profilePath -Encoding UTF8 -Force
    }

    $status.Text = "正在配置执行策略..."
    $form.Refresh()
    try { Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force -ErrorAction SilentlyContinue } catch {}

    $status.Text = "安装完成！"
    Start-Sleep 1

    [System.Windows.Forms.MessageBox]::Show(
        "Aural 安装完成！`n`n• 新对话自动生效`n• PowerShell 输入 tts '文字' 手动朗读`n• 对话中输入 TTS 重听上一条",
        "Aural", "OK", "Information")
    $form.Close()
})

$cancelBtn.Add_Click({ $form.Close() })

$form.ShowDialog() | Out-Null

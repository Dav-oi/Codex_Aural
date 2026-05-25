; Aural v1.4.1"Aural"
#define MyAppVersion "1.4.1"
#define MyAppPublisher "Dave-oioioi"
#define MyAppURL "https://github.com/Dave-oioioi/Codex_Aural"

[Setup]
AppId={{A7F3C8D2-1B4E-4A5F-9E6C-3D8F2A1B7C5E}}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
AppUpdatesURL={#MyAppURL}
DefaultDirName={userdocs}\Codex\Aural
DefaultGroupName={#MyAppName}
AllowNoIcons=yes
OutputDir=.\
OutputBaseFilename=Aural-Setup-v1.4.1
Compression=lzma
SolidCompression=yes
WizardStyle=modern
PrivilegesRequired=lowest
DisableWelcomePage=no
DisableProgramGroupPage=yes
DisableDirPage=no
DisableReadyPage=no
LicenseFile=README.md

[Messages]
WelcomeLabel1=【Aural — 让 Codex 开口说话！！！】
WelcomeLabel2=Dave-oioioi/Codex_Aural%nhttps://github.com/Dave-oioioi/Codex_Aural

[Files]
; Embedded Python (portable, zero-dependency)
Source: "python-embed\*"; DestDir: "{userappdata}\.codex\skills\aural-skill\scripts\python-embed"; Flags: ignoreversion recursesubdirs
; Core scripts → Aural skill directory
Source: "tts_speak.py"; DestDir: "{userappdata}\.codex\skills\aural-skill\scripts"; Flags: ignoreversion
Source: "play_mp3.ps1"; DestDir: "{userappdata}\.codex\skills\aural-skill\scripts"; Flags: ignoreversion
Source: "tts_bg.ps1"; DestDir: "{userappdata}\.codex\skills\aural-skill\scripts"; Flags: ignoreversion
Source: "install.ps1"; DestDir: "{userappdata}\.codex\skills\aural-skill\scripts"; Flags: ignoreversion
Source: "AGENTS.md"; DestDir: "{userappdata}\.codex"; Flags: ignoreversion
Source: "profile.ps1"; DestDir: "{userdocs}\WindowsPowerShell"; Flags: ignoreversion
; Reference files → install directory
Source: "README.md"; DestDir: "{app}"; Flags: ignoreversion
Source: "tts_install.py"; DestDir: "{app}"; Flags: ignoreversion
[Run]
Filename: "powershell.exe"; Parameters: "-NoProfile -ExecutionPolicy Bypass -File ""{userappdata}\.codex\skills\aural-skill\scripts\install.ps1"" -Quiet"; \
    Flags: runhidden waituntilterminated; StatusMsg: "Installing edge_tts and configuring..."; \
    Description: "Install dependencies and configure"

[Code]
procedure CurStepChanged(CurStep: TSetupStep);
var
  PostInstallPath: String;
begin
  if CurStep = ssPostInstall then
  begin
    PostInstallPath := ExpandConstant('{app}\post_install.ps1');
    if not SaveStringToFile(PostInstallPath,
      '$ErrorActionPreference = "Stop"' + #13#10 +
      'Write-Host "Aural - Post-install setup..." -ForegroundColor Cyan' + #13#10 +
      '# Run main installer' + #13#10 +
      '$installScript = "$env:USERPROFILE\.codex\skills\aural-skill\scripts\install.ps1"' + #13#10 +
      'if (Test-Path $installScript) {' + #13#10 +
      '    & $installScript' + #13#10 +
      '}' + #13#10 +
      '# Execution policy' + #13#10 +
      'try { Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force } catch {}' + #13#10 +
      'Write-Host "Aural v1.4.1" -ForegroundColor Green',
      False) then
      Log('Failed to write post_install.ps1');
  end;
end;


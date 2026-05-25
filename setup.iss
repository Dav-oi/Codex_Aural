; Aural v1.4.1
#define MyAppName "Aural"
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
OutputDir=.\releases
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
WelcomeLabel1=【Aural — 让 Codex 开口说话】
WelcomeLabel2=Dave-oioioi/Codex_Aural%nhttps://github.com/Dave-oioioi/Codex_Aural

[Files]
; Embedded Python (portable, zero-dependency)
Source: "python-embed\*"; DestDir: "{userappdata}\.codex\skills\aural-skill\scripts\python-embed"; Flags: ignoreversion recursesubdirs
; Core scripts → Aural skill directory (single source: aural-plugin)
Source: "aural-plugin\skills\aural\scripts\tts_speak.py"; DestDir: "{userappdata}\.codex\skills\aural-skill\scripts"; Flags: ignoreversion
Source: "aural-plugin\skills\aural\scripts\tts_bg.ps1"; DestDir: "{userappdata}\.codex\skills\aural-skill\scripts"; Flags: ignoreversion
Source: "aural-plugin\skills\aural\scripts\install.ps1"; DestDir: "{userappdata}\.codex\skills\aural-skill\scripts"; Flags: ignoreversion
; Metadata files
Source: "aural-plugin\skills\aural\SKILL.md"; DestDir: "{userappdata}\.codex\skills\aural-skill"; Flags: ignoreversion
Source: "aural-plugin\skills\aural\agents\openai.yaml"; DestDir: "{userappdata}\.codex\skills\aural-skill\agents"; Flags: ignoreversion
Source: "aural-plugin\skills\aural\assets\icon-small.svg"; DestDir: "{userappdata}\.codex\skills\aural-skill\assets"; Flags: ignoreversion
Source: "aural-plugin\skills\aural\assets\icon-large.png"; DestDir: "{userappdata}\.codex\skills\aural-skill\assets"; Flags: ignoreversion
Source: "aural-plugin\skills\aural\LICENSE.txt"; DestDir: "{userappdata}\.codex\skills\aural-skill"; Flags: ignoreversion
; Global AGENTS.md registration
Source: "AGENTS.md"; DestDir: "{userappdata}\.codex"; Flags: ignoreversion
; PowerShell profile
Source: "profile.ps1"; DestDir: "{userdocs}\WindowsPowerShell"; Flags: ignoreversion
; Reference files
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
      '$installScript = "$env:USERPROFILE\.codex\skills\aural-skill\scripts\install.ps1"' + #13#10 +
      'if (Test-Path $installScript) {' + #13#10 +
      '    & $installScript' + #13#10 +
      '}' + #13#10 +
      'try { Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force } catch {}' + #13#10 +
      'Write-Host "Aural v1.4.1" -ForegroundColor Green',
      False) then
      Log('Failed to write post_install.ps1');
  end;
end;
; ============================================================
;  Aural — Inno Setup 欢迎页面模板
;  WelcomeLabel1 = 标题   WelcomeLabel2 = 副标题
; ============================================================

[Setup]
AppName=Aural
AppVersion=1.1
AppPublisher=Dave_
DefaultDirName={userdocs}\Codex\Aural
DisableWelcomePage=no
WizardStyle=modern

; ═══════════════════════════════════════════════════════
;  欢迎页文字
; ═══════════════════════════════════════════════════════
[Messages]
; 标题 (大号粗体)
WelcomeLabel1=【Aural — 让 Codex 开口说话！！！】

; 描述文字 (%n = 换行)
WelcomeLabel2=Dav-oi/Codex_Aural%n%nhttps://github.com/Dav-oi/Codex_Aural

; ═══════════════════════════════════════════════════════
;  欢迎页样式定制
; ═══════════════════════════════════════════════════════

[Code]
procedure InitializeWizard;
begin
  { ── 标题字体 ── }
  WizardForm.WelcomeLabel1.Font.Name := 'Microsoft YaHei';
  WizardForm.WelcomeLabel1.Font.Size := 20;
  WizardForm.WelcomeLabel1.Font.Color := $D27800;  { 蓝色 }

  { ── 副标题字体 ── }
  WizardForm.WelcomeLabel2.Font.Name := 'Microsoft YaHei';
  WizardForm.WelcomeLabel2.Font.Size := 11;
  WizardForm.WelcomeLabel2.Font.Color := $666666;   { 灰色 }

  { ── 居中 ── }
  WizardForm.WelcomeLabel1.Width := WizardForm.ClientWidth - 40;
  WizardForm.WelcomeLabel1.Left := 20;
  WizardForm.WelcomeLabel2.Top := WizardForm.WelcomeLabel1.Top + WizardForm.WelcomeLabel1.Height + 20;
  WizardForm.WelcomeLabel2.Width := WizardForm.ClientWidth - 40;
  WizardForm.WelcomeLabel2.Left := 20;
end;

; ═══════════════════════════════════════════════════════
;  预览效果:
;
;  ┌─────────────────────────────────────────┐
;  │  【Aural — 让 Codex 开口说话！！！】      │
;  │                                         │
;  │  Dav-oi/Codex_Aural                     │
;  │  https://github.com/Dav-oi/Codex_Aural  │
;  │                                         │
;  │              [下一步]  [取消]            │
;  └─────────────────────────────────────────┘
; ═══════════════════════════════════════════════════════


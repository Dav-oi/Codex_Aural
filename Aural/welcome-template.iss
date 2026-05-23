; ============================================================
;  Aural — Inno Setup 欢迎页面模板
;  修改 WelcomeLabel1 / WelcomeLabel2 / [Code] 区域即可
; ============================================================

[Setup]
AppName=Aural
AppVersion=1.0
AppPublisher=Dave_
DefaultDirName={userdocs}\Codex\Aural
DisableWelcomePage=no
WizardStyle=modern

; ═══════════════════════════════════════════════════════
;  1. 基础文字 (最简单)
; ═══════════════════════════════════════════════════════
[Messages]
; 标题 (大号粗体)
WelcomeLabel1=【Aural】

; 描述文字 (%n = 换行)
WelcomeLabel2=Dave%nAural - v1.0 让 Codex 说话！！！

; ═══════════════════════════════════════════════════════
;  2. 带图标的欢迎页 (需要准备图片文件)
; ═══════════════════════════════════════════════════════
; WizardImageFile=welcome-banner.bmp     ; 左侧大图 164x314
; WizardSmallImageFile=welcome-icon.bmp  ; 右上小图 55x55


; ═══════════════════════════════════════════════════════
;  3. [Code] 高级定制 (字体、颜色、链接、富文本)
;    取消下面注释即可启用
; ═══════════════════════════════════════════════════════

[Code]
procedure InitializeWizard;
begin
  { ── 修改标题字体 ── }
  WizardForm.WelcomeLabel1.Font.Name := 'Microsoft YaHei';
  WizardForm.WelcomeLabel1.Font.Size := 20;
  WizardForm.WelcomeLabel1.Font.Color := $D27800;  { 蓝色 0x0078D2 }

  { ── 修改描述字体 ── }
  WizardForm.WelcomeLabel2.Font.Name := 'Microsoft YaHei';
  WizardForm.WelcomeLabel2.Font.Size := 11;
  WizardForm.WelcomeLabel2.Font.Color := $666666;   { 灰色 }

  { ── 让标题居中 ── }
  WizardForm.WelcomeLabel1.Width := WizardForm.ClientWidth - 40;
  WizardForm.WelcomeLabel1.Left := 20;

  { ── 调整描述位置 ── }
  WizardForm.WelcomeLabel2.Top := WizardForm.WelcomeLabel1.Top + WizardForm.WelcomeLabel1.Height + 20;
  WizardForm.WelcomeLabel2.Width := WizardForm.ClientWidth - 40;
  WizardForm.WelcomeLabel2.Left := 20;
end;


; ═══════════════════════════════════════════════════════
;  模板效果预览:
;
;  ┌─────────────────────────────────────┐
;  │  [图标]                             │
;  │                                     │
;  │  【Aural】        (20pt, 蓝色粗体)    │
;  │                                     │
;  │  Dave            (11pt, 灰色)        │
;  │  《这一行功能介绍》 (11pt, 灰色)        │
;  │                                     │
;  │              [下一步]  [取消]        │
;  └─────────────────────────────────────┘
; ═══════════════════════════════════════════════════════



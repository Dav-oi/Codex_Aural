# Global AGENTS.md — Dave's Project Conventions

## README 风格规范

编写或更新 README.md 时遵循以下格式：

### 结构要求

1. **顶部徽章区** — 版本号、License 等 Badge（shields.io）
2. **一句话简介** — 项目名称 + 核心价值主张
3. **功能概述** — 3-5 条要点，每条用 **粗体标签** 开头
4. **快速安装** — 至少两种方式，优先推荐一键方案，代码块标注语言
5. **目录结构** — 用 Markdown 表格，两列（目录 | 说明）
6. **技术栈** — 简短列表，key: value 格式
7. **License 尾部** — 作者 + 链接

### 风格规则

- 用 `---` 分隔大区块
- 安装命令用代码块并标注语言（```powershell / ```bash）
- 链接始终用 Markdown `[text](url)` 格式
- 版本号统一从 setup.iss 或 package.json 提取
- 中文为主，技术术语保留英文

### 示例模板

```markdown
# Project Name — 一句话描述

[![Release](https://img.shields.io/badge/Release-v1.0-color)](link)
[![License](https://img.shields.io/badge/License-MIT-green)](./LICENSE)

---

## 功能概述

1. **特性A** — 简短说明
2. **特性B** — 简短说明

---

## 快速安装

### 方式一：一键安装（推荐）

下载 [Setup.exe](link)，双击运行。

### 方式二：手动安装

```bash
git clone ...
```

---

## 目录结构

| 目录 | 说明 |
|------|------|
| `src/` | 源码 |
| `docs/` | 文档 |

---

## License

MIT © [Author](link)
```

---

## Skill 规范

所有 skill 必须包含：
- `SKILL.md` — YAML frontmatter (name + description)
- `agents/openai.yaml` — display_name, brand_color, icon_small, icon_large, default_prompt
- `assets/` — icon-small.svg + icon-large.png
- `LICENSE.txt` — MIT

---

## 安装包规范

- 版本号统一管理，发布前同步 `setup.iss` + `welcome-template.iss` + `SKILL.md`
- 编译产物放入 `releases/` 目录
- 安装路径统一使用 `skills/<skill-name>/`

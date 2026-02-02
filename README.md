# Intelephense License Patcher

这是一个用于解锁 [Intelephense](https://intelephense.com/) 扩展高级功能（Premium Features）的 Bash 脚本。它通过修改本地扩展文件，绕过许可证验证机制。

支持多种基于 VS Code 的编辑器，如 **VS Code**, **Cursor**, **Windsurf**, **VSCodium** 等。

---

## ✨ 功能特性

- **自动检测**：自动识别系统默认路径下安装的编辑器扩展目录。
- **多编辑器支持**：
  - VS Code (`~/.vscode/extensions`)
  - Cursor (`~/.cursor/extensions`)
  - VS Code Insiders
  - Windsurf / Trae / Kiro / Antigravity
  - VSCodium
- **无感激活**：脚本会自动修改校验逻辑，并注入默认 Key (`123456`)，无需手动输入。
- **幂等性**：支持重复运行，不会破坏已修改的文件。

## 🛠 前置要求

运行此脚本需要系统中安装以下工具：
1. **Bash** (Shell 环境)
2. **Python 3** (用于处理文件内容的替换逻辑)

## 🚀 使用指南

### 📸 功能预览 (Premium Features)

激活后，你可以享受到 Intelephense 的所有高级功能，例如 **智能引用计数 (References)**、**增强型类型探测**、**重命名重构**等：

![Intelephense Premium Features](screenshots/2.png)

### 1. macOS / Linux

直接在终端中运行即可：

```bash
# 赋予执行权限
chmod +x patch-intelephense-licence.sh

# 运行补丁
./patch-intelephense-licence.sh
```

**只针对特定编辑器运行：**
```bash
./patch-intelephense-licence.sh --only Cursor
```

### 2. Windows

由于脚本是 `.sh` 格式，Windows 用户需要通过 **Git Bash** 或 **WSL** 运行。

#### 方法 A：使用 Git Bash (推荐)
1. 在项目文件夹中右键，选择 "Open Git Bash here"。
2. 输入命令：
   ```bash
   ./patch-intelephense-licence.sh
   ```
   *注意：Git Bash 通常能正确映射用户目录，但如果脚本找不到路径，请尝试手动指定路径（见下文）。*

#### 方法 B：使用 WSL
如果在 WSL 环境下使用 VS Code Remote，直接按 Linux 方法运行即可。如果是修补 Windows 本地的 VS Code，建议使用 Git Bash。

### 3. 自定义扩展路径 (高级用法)

如果你的扩展安装在非标准路径，或者脚本未自动检测到，可以通过环境变量 `INTELPHP_EXT_DIRS` 指定路径：

```bash
# 多个路径用冒号 : 分隔
export INTELPHP_EXT_DIRS="/path/to/custom/extensions:/another/path"
./patch-intelephense-licence.sh
```

---

## ⚠️ 重要提示

1. **重启生效**：脚本执行成功后，**必须完全退出编辑器**（macOS 请使用 `Cmd+Q`，Windows 请确保后台进程已结束）并重新打开，激活才会生效。
2. **版本更新**：如果 Intelephense 扩展进行了自动更新，补丁可能会失效。此时只需重新运行脚本即可。

---

## ⚖️ 免责声明 (Disclaimer)

> **仅供学习与研究用途 (For Educational Purposes Only)**

1. **版权说明**：本脚本仅供旨在研究软件逆向工程、代码分析或个人学习使用。
2. **非商业用途**：请勿将此脚本用于任何商业环境或生产环境。
3. **推荐正版**：Intelephense 是一款优秀的 PHP 生产力工具，开发者付出了大量心血。如果你觉得它对你的工作有帮助，**强烈建议购买正版 License 支持作者**。
   - 官网购买地址: [https://intelephense.com/](https://intelephense.com/)
4. **责任豁免**：使用本脚本产生的任何后果（包括但不限于软件损坏、数据丢失或法律纠纷）由使用者自行承担，脚本作者不承担任何法律责任。

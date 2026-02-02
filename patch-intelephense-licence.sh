#!/usr/bin/env bash
# Intelephense 激活绕过脚本（支持多种 VSCode 系编辑器）
# 可重复执行。执行后需完全退出对应编辑器 (如 Cursor: Cmd+Q) 再重新打开。
#
# 已知基于 VSCode / Electron 的编辑器（扩展目录 ~/.<name>/extensions）：
#   [1] VS Code          ~/.vscode/extensions
#   [2] Cursor           ~/.cursor/extensions
#   [3] VS Code Insiders ~/.vscode-insiders/extensions
#   [4] Windsurf          ~/.windsurf/extensions
#   [5] Kiro              ~/.kiro/extensions
#   [6] Antigravity       ~/.antigravity/extensions
#   [7] Trae              ~/.trae/extensions
#   [8] VSCodium          ~/.vscode-oss/extensions
#   Zed 为独立实现，扩展体系不同，不适用本脚本。
#
# 仅对「存在且含 Intelephense」的编辑器目录执行补丁；可通过环境变量追加目录。
# 用法：
#   ./patch-intelephense-licence.sh
#   INTELPHP_EXT_DIRS="/path/to/extensions:/path/to/other" ./patch-intelephense-licence.sh
#   ./patch-intelephense-licence.sh --only Cursor
set -e

GLOB="bmewburn.vscode-intelephense-client-"*

# 编辑器显示名 -> 扩展根目录（可增改）
declare -a EDITOR_NAMES
declare -a EDITOR_DIRS
EDITOR_NAMES=("VS Code" Cursor "VS Code Insiders" Windsurf Kiro Antigravity Trae VSCodium)
EDITOR_DIRS=(
  "${HOME}/.vscode/extensions"
  "${HOME}/.cursor/extensions"
  "${HOME}/.vscode-insiders/extensions"
  "${HOME}/.windsurf/extensions"
  "${HOME}/.kiro/extensions"
  "${HOME}/.antigravity/extensions"
  "${HOME}/.trae/extensions"
  "${HOME}/.vscode-oss/extensions"
)

# 可选：仅处理指定编辑器（--only <名称>）
ONLY_EDITOR=""
if [[ "${1:-}" == "--only" && -n "${2:-}" ]]; then
  ONLY_EDITOR="$2"
fi

# 环境变量追加目录（冒号分隔），无名称时用路径显示
EXTRA_DIRS=()
if [[ -n "${INTELPHP_EXT_DIRS:-}" ]]; then
  IFS=: read -ra EXTRA_DIRS <<< "$INTELPHP_EXT_DIRS"
fi

# 在指定扩展根目录下查找 Intelephense，找到则输出其绝对路径并返回 0，否则返回 1
find_intelephense_in() {
  local ext_dir="$1"
  local found
  found=()
  for d in "${ext_dir}"/${GLOB}; do
    [[ -d "$d" ]] && found+=("$d")
  done
  if [[ ${#found[@]} -eq 0 ]]; then
    return 1
  fi
  echo "${found[0]}"
  return 0
}

# 对单个扩展目录执行补丁（EXT_BASE 为 Intelephense 扩展目录绝对路径）
patch_one() {
  local ext_base="$1"
  local ls_file="${ext_base}/node_modules/intelephense/lib/intelephense.js"
  local ext_file="${ext_base}/lib/extension.js"

  if [[ ! -f "$ls_file" || ! -f "$ext_file" ]]; then
    echo "  跳过: 缺少 intelephense.js 或 extension.js"
    return 1
  fi

  python3 << PY
ls_file = """$ls_file"""
ext_file = """$ext_file"""

# ---------- 1. 服务端：activationResult setter，123456 强制已激活 ----------
old1 = 'set activationResult(e){e&&d.verify(e)&&e.message.licenceKey===this._key?this._activationResult=e:this._activationResult=void 0}'
new1 = 'set activationResult(e){if(this._key==="123456"){this._activationResult={message:{resultCode:1,licenceKey:"123456"}};return}e&&d.verify(e)&&e.message.licenceKey===this._key?this._activationResult=e:this._activationResult=void 0}'
with open(ls_file, 'r') as f:
    s = f.read()
if new1 in s:
    print("   [intelephense.js] setter 已为 123456 激活，跳过")
elif old1 in s:
    s = s.replace(old1, new1, 1)
    with open(ls_file, 'w') as f:
        f.write(s)
    print("   [intelephense.js] setter 已改为 123456 激活")
else:
    print("   [intelephense.js] 未找到原 setter 字符串，可能已改过或版本不同，跳过 setter")

# ---------- 2. 服务端：isActive / isRevoked / isExpired 恒为已激活 ----------
old2 = 'isActive(){return void 0!==this._activationResult&&1===this._activationResult.message.resultCode}isRevoked(){return void 0!==this._activationResult&&3===this._activationResult.message.resultCode}isExpired(){return!1}'
new2 = 'isActive(){return!0}isRevoked(){return!1}isExpired(){return!1}'
with open(ls_file, 'r') as f:
    s = f.read()
if new2 in s:
    print("   [intelephense.js] isActive/isRevoked/isExpired 已为恒已激活，跳过")
elif old2 in s:
    s = s.replace(old2, new2, 1)
    with open(ls_file, 'w') as f:
        f.write(s)
    print("   [intelephense.js] isActive/isRevoked/isExpired 已改为恒已激活")
else:
    print("   [intelephense.js] 未找到原 isActive 字符串，可能已改过或版本不同，跳过")

# ---------- 3. 客户端：licenceKey 无值时默认 123456 ----------
old3 = 'licenceKey:e.globalState.get(T)'
new3 = 'licenceKey:e.globalState.get(T)||"123456"'
with open(ext_file, 'r') as f:
    s = f.read()
if new3 in s:
    print("   [extension.js] licenceKey 已带 123456 回退，跳过")
elif old3 in s:
    s = s.replace(old3, new3, 1)
    with open(ext_file, 'w') as f:
        f.write(s)
    print("   [extension.js] licenceKey 已改为无值时使用 123456")
else:
    print("   [extension.js] 未找到原 licenceKey 字符串，可能已改过或版本不同，跳过")
PY
}

PATCHED=()

# 1) 处理预设编辑器
for i in "${!EDITOR_NAMES[@]}"; do
  name="${EDITOR_NAMES[$i]}"
  dir="${EDITOR_DIRS[$i]}"
  if [[ -n "$ONLY_EDITOR" && "$name" != "$ONLY_EDITOR" ]]; then
    continue
  fi
  if [[ ! -d "$dir" ]]; then
    continue
  fi
  ext_base=""
  ext_base=$(find_intelephense_in "$dir") || true
  if [[ -z "$ext_base" ]]; then
    continue
  fi
  echo "=== $name ($dir) ==="
  echo "   扩展目录: $ext_base"
  if patch_one "$ext_base"; then
    PATCHED+=("$name")
  fi
  echo ""
done

# 2) 处理环境变量中的额外目录
for dir in "${EXTRA_DIRS[@]}"; do
  dir="${dir//\~/$HOME}"
  [[ -z "$dir" || ! -d "$dir" ]] && continue
  ext_base=""
  ext_base=$(find_intelephense_in "$dir") || true
  if [[ -z "$ext_base" ]]; then
    continue
  fi
  echo "=== 自定义: $dir ==="
  echo "   扩展目录: $ext_base"
  if patch_one "$ext_base"; then
    PATCHED+=("$dir")
  fi
  echo ""
done

# 汇总
if [[ ${#PATCHED[@]} -eq 0 ]]; then
  echo "未在任何已检测的编辑器中找到 Intelephense 扩展。"
  echo "请确认：1) 已安装 Intelephense；2) 扩展目录正确（可设置 INTELPHP_EXT_DIRS 追加）。"
  exit 1
fi

echo "已处理: ${PATCHED[*]}"
echo "请完全退出对应编辑器 (如 Cursor: Cmd+Q) 后重新打开使生效。"

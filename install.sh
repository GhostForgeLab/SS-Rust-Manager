#!/usr/bin/env bash
set -euo pipefail

REPO_RAW="https://raw.githubusercontent.com/GhostForgeLab/SS-Rust-Manager/main"
CONFIG_DIR="/etc/shadowsocks-rust"
CONFIG="$CONFIG_DIR/config.json"
SERVICE_FILE="/etc/systemd/system/shadowsocks-rust.service"
SERVICE="shadowsocks-rust.service"

need_root() {
  [[ ${EUID:-$(id -u)} -eq 0 ]] || { echo "错误：请使用 root 权限运行。"; exit 1; }
}

install_deps() {
  local need=()
  for c in curl jq tar xz python3 openssl qrencode ip; do
    command -v "$c" >/dev/null 2>&1 || need+=("$c")
  done
  if ((${#need[@]})); then
    echo "安装依赖..."
    apt-get update
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
      curl jq xz-utils python3 openssl qrencode iproute2 ca-certificates coreutils
  fi
}

install_manager_files() {
  local here td cleanup_cmd
  here="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd || true)"
  td=""

  if [[ -f "$here/ssmenu" && -f "$here/ssupdate" ]]; then
    install -m 0755 "$here/ssmenu" /usr/local/bin/ssmenu
    install -m 0755 "$here/ssupdate" /usr/local/bin/ssupdate
  else
    td="$(mktemp -d)"
    printf -v cleanup_cmd 'rm -rf -- %q' "$td"
    trap "$cleanup_cmd" EXIT
    echo "从 GitHub 下载管理脚本..."
    curl -fsSL --retry 3 "$REPO_RAW/ssmenu" -o "$td/ssmenu"
    curl -fsSL --retry 3 "$REPO_RAW/ssupdate" -o "$td/ssupdate"
    install -m 0755 "$td/ssmenu" /usr/local/bin/ssmenu
    install -m 0755 "$td/ssupdate" /usr/local/bin/ssupdate
  fi
}

create_config_if_missing() {
  mkdir -p "$CONFIG_DIR"
  if [[ -e "$CONFIG" || -L "$CONFIG" ]]; then
    echo "检测到现有配置：$CONFIG"
    echo "已保护，不覆盖。"
    return
  fi

  echo
  echo "=== 首次创建 Shadowsocks Rust 配置 ==="
  local port method_choice method password key_bytes=0
  read -r -p "监听端口 [8388]：" port
  port="${port:-8388}"
  [[ "$port" =~ ^[0-9]+$ ]] && ((port>=1 && port<=65535)) || { echo "端口无效"; exit 1; }

  echo "加密方式："
  echo "1. chacha20-ietf-poly1305（默认）"
  echo "2. aes-256-gcm"
  echo "3. 2022-blake3-aes-128-gcm（SS2022）"
  echo "4. 2022-blake3-aes-256-gcm（SS2022）"
  read -r -p "选择 [1]：" method_choice
  case "${method_choice:-1}" in
    1) method="chacha20-ietf-poly1305" ;;
    2) method="aes-256-gcm" ;;
    3) method="2022-blake3-aes-128-gcm"; key_bytes=16 ;;
    4) method="2022-blake3-aes-256-gcm"; key_bytes=32 ;;
    *) echo "选择无效"; exit 1 ;;
  esac

  if ((key_bytes)); then
    echo "SS2022 需要 $key_bytes 字节随机密钥（Base64 编码），不能使用普通自定义密码。"
    read -r -p "密钥（直接回车自动生成）：" password
    if [[ -z "$password" ]]; then
      password="$(openssl rand -base64 "$key_bytes" | tr -d '\n')"
    fi
    if ! python3 - "$password" "$key_bytes" <<'PY'
import base64, sys
try:
    key = base64.b64decode(sys.argv[1], validate=True)
    valid = len(key) == int(sys.argv[2]) and base64.b64encode(key).decode() == sys.argv[1]
except (ValueError, UnicodeError):
    valid = False
sys.exit(0 if valid else 1)
PY
    then
      echo "密钥无效：请使用 $key_bytes 字节随机密钥的标准 Base64 编码。" >&2
      exit 1
    fi
  else
    read -r -p "密码（直接回车自动生成）：" password
    if [[ -z "$password" ]]; then
      password="$(openssl rand -base64 24 | tr -d '\n')"
    fi
  fi

  (umask 077; python3 - "$CONFIG" "$port" "$method" "$password" <<'PY'
import json, sys
path, port, method, password = sys.argv[1], int(sys.argv[2]), sys.argv[3], sys.argv[4]
data = {
    "server": "0.0.0.0",
    "server_port": port,
    "password": password,
    "method": method,
    "mode": "tcp_and_udp"
}
with open(path, "x", encoding="utf-8") as f:
    json.dump(data, f, ensure_ascii=False, indent=2)
    f.write("\n")
PY
  )
  chmod 600 "$CONFIG"

  echo
  echo "配置已创建：$CONFIG"
  echo "端口：$port"
  echo "加密：$method"
  echo "密钥/密码：$password"
  echo "请保存好以上信息。"
}

create_service_if_missing() {
  if [[ -e "$SERVICE_FILE" || -L "$SERVICE_FILE" ]]; then
    echo "检测到现有 systemd 服务文件，已保留：$SERVICE_FILE"
    return
  fi
  cat > "$SERVICE_FILE" <<'EOF'
[Unit]
Description=Shadowsocks Rust Server
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
ExecStart=/usr/local/bin/ssserver -c /etc/shadowsocks-rust/config.json
Restart=on-failure
RestartSec=3
LimitNOFILE=1048576

[Install]
WantedBy=multi-user.target
EOF
  systemctl daemon-reload
}

verify_install() {
  local failed=0
  if [[ -x /usr/local/bin/ssserver ]]; then echo "[ OK ] ssserver"; else echo "[FAIL] ssserver 缺失"; failed=1; fi
  if [[ -x /usr/local/bin/ssmenu ]]; then echo "[ OK ] ssmenu"; else echo "[FAIL] ssmenu 缺失"; failed=1; fi
  if [[ -f "$CONFIG" ]]; then echo "[ OK ] config.json"; else echo "[FAIL] config.json 缺失"; failed=1; fi
  if [[ -f "$SERVICE_FILE" ]]; then echo "[ OK ] systemd 服务文件"; else echo "[FAIL] systemd 服务文件缺失"; failed=1; fi
  if systemctl is-active --quiet "$SERVICE"; then echo "[ OK ] 服务正在运行"; else echo "[FAIL] 服务未运行"; failed=1; fi
  ((failed == 0))
}

main() {
  need_root
  install_deps
  install_manager_files

  if [[ ! -x /usr/local/bin/ssserver ]]; then
    echo
    echo "未检测到 ssserver，开始从 shadowsocks-rust 官方 Release 安装最新版..."
    /usr/local/bin/ssupdate install
  else
    echo "检测到现有 ssserver：$(/usr/local/bin/ssserver --version 2>/dev/null | head -n1 || true)"
    echo "默认不覆盖现有二进制；可在菜单中检查更新。"
  fi

  create_config_if_missing
  create_service_if_missing

  systemctl daemon-reload
  systemctl enable "$SERVICE" >/dev/null 2>&1 || true
  if systemctl restart "$SERVICE"; then
    echo "Shadowsocks Rust 服务已启动。"
  else
    echo "警告：服务启动失败，请运行 ssmenu -> 14. 运行环境自检 查看原因。"
  fi

  echo
  echo "=== 安装完成检测 ==="
  if ! verify_install; then
    echo "安装未完成，请检查以上失败项或运行 ssmenu -> 20. 修复安装环境。" >&2
    return 1
  fi

  echo
  echo "=================================="
  echo "SS-Rust-Manager v1.1.2 安装完成"
  echo "=================================="
  echo "运行管理菜单：ssmenu"
}

main "$@"

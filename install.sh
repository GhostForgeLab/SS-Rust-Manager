#!/bin/bash
set -e

if [ "$(id -u)" -ne 0 ]; then
  echo "请使用 root 权限运行"
  exit 1
fi

install -m 755 ssmenu /usr/local/bin/ssmenu
install -m 755 ssupdate /usr/local/bin/ssupdate

echo "Shadowsocks Rust Manager 安装完成"
echo "运行：ssmenu"

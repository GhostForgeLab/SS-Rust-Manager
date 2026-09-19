# SS-Rust-Manager

Shadowsocks Rust 轻量管理菜单工具。

用于已经安装并配置好 **Shadowsocks Rust** 的 VPS，提供常用服务管理、配置管理、更新、备份、网络设置等功能。

> 本项目仅安装管理菜单，不安装 Shadowsocks Rust 服务端本体，不包含 `config.json`，不包含服务器密码及节点信息。

---

# 一、一键安装

## 推荐方式

在新 VPS 上直接使用 root 执行：

```bash
bash -c 'set -e; command -v curl >/dev/null 2>&1 || { apt-get update && apt-get install -y curl; }; d=$(mktemp -d); cd "$d"; for f in ssmenu ssupdate install.sh; do curl -fsSLO "https://raw.githubusercontent.com/lph112358/SS-Rust-Manager/main/$f"; done; bash install.sh; cd /; rm -rf "$d"'
```

安装完成后直接运行：

```bash
ssmenu
```

即可进入 Shadowsocks Rust 管理菜单。

---

# 二、管理菜单功能

当前管理菜单包含：

```text
1.  查看运行状态
2.  启动服务
3.  停止服务
4.  重启服务
5.  查看配置
6.  编辑配置
7.  生成 ss:// 链接和二维码
8.  查看实时日志
9.  查看版本
10. 检查并更新
11. 备份当前配置
12. 恢复配置
13. 开机自启管理
14. 运行环境自检
15. 查看服务器连接信息
16. 选择 IPv4 / IPv6 出站
17. 开启 / 检查 BBR
18. 快速修改端口
0.  退出
```

---

# 三、常用命令

启动管理菜单：

```bash
ssmenu
```

菜单程序安装位置：

```text
/usr/local/bin/ssmenu
```

更新脚本：

```text
/usr/local/bin/ssupdate
```

---

# 四、Release 安装方式

除了在线一键安装，也可以从 GitHub Releases 下载：

```text
SS-Rust-Manager-v1.0.0.tar.gz
```

上传到 VPS 后执行：

```bash
tar -xzf SS-Rust-Manager-v1.0.0.tar.gz
cd SS-Rust-Manager
bash install.sh
```

安装完成：

```bash
ssmenu
```

---

# 五、适用场景

本项目适用于：

* VPS 已经安装 Shadowsocks Rust
* Shadowsocks Rust 已经配置完成
* 只需要安装或恢复管理菜单
* 更换 VPS 后快速恢复管理工具
* 管理菜单丢失后重新安装

---

# 六、本项目不会做什么

本项目不会：

* 安装 `ssserver`
* 创建新的 Shadowsocks 节点
* 上传或恢复旧 VPS 的 `config.json`
* 保存 Shadowsocks 密码
* 保存服务器 IP
* 自动恢复旧 VPS 的节点配置
* 自动恢复旧服务器的数据

因此可以将本项目放在公开 GitHub 仓库中。

---

# 七、与完整恢复包的区别

## SS-Rust-Manager

只恢复：

```text
ssmenu
ssupdate
```

适合已经安装好 Shadowsocks Rust 的 VPS。

---

## ss-vps-restore.tar.gz

属于完整 VPS Shadowsocks Rust 恢复包，其中可能包含：

```text
restore.sh
ssserver
ssmenu
ssupdate
config.json
shadowsocks-rust.service
```

完整恢复包可能包含真实 Shadowsocks 配置和密码。

**不建议上传到公开 GitHub。**

---

# 八、新 VPS 推荐流程

如果新 VPS 已经安装并配置好 Shadowsocks Rust：

直接执行：

```bash
bash -c 'set -e; command -v curl >/dev/null 2>&1 || { apt-get update && apt-get install -y curl; }; d=$(mktemp -d); cd "$d"; for f in ssmenu ssupdate install.sh; do curl -fsSLO "https://raw.githubusercontent.com/lph112358/SS-Rust-Manager/main/$f"; done; bash install.sh; cd /; rm -rf "$d"'
```

然后：

```bash
ssmenu
```

即可恢复管理菜单。

---

# 九、更新管理菜单

以后如果 GitHub 仓库里的：

```text
ssmenu
ssupdate
```

进行了更新，可以再次执行一键安装命令。

新版本会重新复制到：

```text
/usr/local/bin/ssmenu
/usr/local/bin/ssupdate
```

相当于覆盖更新管理菜单。

---

# 十、环境

已验证：

* Debian 13
* Shadowsocks Rust
* systemd
* Bash

主要依赖：

* curl
* systemd
* Shadowsocks Rust

---

# 十一、安全说明

本 GitHub 仓库建议只保存：

```text
ssmenu
ssupdate
install.sh
README.md
```

不要上传：

```text
config.json
服务器密码
Shadowsocks 密码
真实节点配置
私人密钥
```

---

## Version

`SS-Rust-Manager v1.0.0`

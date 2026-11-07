# SS-Rust-Manager

Shadowsocks Rust 一键安装、更新及管理工具。

## v1.1.3 新增

- 菜单 `21` 设置入站监听：仅 IPv4、仅 IPv6、IPv4 + IPv6 双栈
- 切换前自动备份，原子更新监听配置；服务重启失败或立即退出时恢复原配置并尝试重新启动
- 保留端口、密码、加密方式及出站设置；已有配置不会因更新脚本而自动改变
- 菜单 `7` 根据监听类型生成链接，双栈生成两种地址的链接，IPv6 地址使用方括号
- 菜单 `15` 显示当前入站监听配置；菜单 `16` 仍仅用于出站设置

### 入站监听设置

更新管理脚本后运行 `ssmenu`，选择 `21`：

| 选项 | server | ipv6_only | 用途 |
| --- | --- | --- | --- |
| 1. 仅 IPv4 | `0.0.0.0` | `false` | 只接受 IPv4 连接 |
| 2. 仅 IPv6 | `::` | `true` | 只接受 IPv6 连接 |
| 3. 双栈 | `::` | `false` | 同时接受 IPv4、IPv6 连接 |

这会监听所选类型的所有本机地址。首次安装仍默认仅 IPv4，可安装后使用菜单 `21` 切换。
IPv6 模式需要 VPS 启用 IPv6、客户端具有 IPv6 连通性，并在系统防火墙及云安全组放行对应 SS 端口的 TCP/UDP。
“入站”是客户端连接 VPS，“出站”是 VPS 连接目标网站，两者可分别设置。
多服务器（`servers` 数组）或域名监听配置请使用菜单 `6` 手动编辑。
链接生成需要能够查询对应公网 IP；无法查询时会提示，不会使用另一地址类型替代。

### 更新已安装的管理脚本

以 root 运行下面的命令，仅替换管理菜单，不修改现有配置或重启服务：

```bash
tmp=$(mktemp) && \
  curl -fsSL --retry 3 https://raw.githubusercontent.com/GhostForgeLab/SS-Rust-Manager/main/ssmenu -o "$tmp" && \
  bash -n "$tmp" && \
  install -m 0755 "$tmp" /usr/local/bin/ssmenu
if [ -n "${tmp:-}" ]; then rm -f -- "$tmp"; fi
ssmenu
```

菜单 `10` / `19` 更新的是 Shadowsocks Rust 内核，不负责更新管理菜单。

## v1.1.2 新增

- 首次安装及菜单 `20` 修复缺失配置时，可选择 `2022-blake3-aes-128-gcm` 或 `2022-blake3-aes-256-gcm`
- SS2022 按加密方式生成 16/32 字节随机密钥；手动输入时检查 Base64 格式与密钥长度
- 菜单 `7` 为 SS2022 生成符合 SIP002 的明文且经百分号转义的 `ss://` 链接和二维码
- 已有 `config.json` 仍会保留；重新运行安装脚本不会修改现有加密方式

## v1.1.1 修复

- 修复 Debian 12 全新 VPS 安装时初始化不完整的问题
- 安装结束检查 `ssserver`、`ssmenu`、配置、systemd 服务文件及服务运行状态；未通过时报告失败
- 修复 `config.json` 和 systemd 服务文件缺失时无法从菜单恢复的问题；已有配置不会覆盖
- 修复 `install.sh` 的 RAW 下载地址，改为 `GhostForgeLab/SS-Rust-Manager`
- 修复远程安装和更新成功后临时目录清理可能导致的错误退出
- 菜单 `19` 在更新或重装后完成初始化检查，新增 `20. 修复安装环境`

## v1.1.0 新增

- 全新 Debian VPS 可直接安装官方 `ssserver`
- 自动从 `shadowsocks/shadowsocks-rust` 官方 GitHub Release 获取最新版
- 自动识别 x86_64 / aarch64
- 下载官方静态 Linux musl 构建
- SHA256 校验
- 创建 systemd 服务
- 首次创建配置
- 已有 `config.json` 默认保护，不覆盖
- 菜单新增 `19. 安装 / 重装 Shadowsocks Rust`
- `10. 检查并更新` 直接检查官方版本
- 更新失败时自动回滚旧版 `ssserver`

## 一键安装

全新 VPS 或已有 Shadowsocks Rust 的 VPS 都可以执行：

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/GhostForgeLab/SS-Rust-Manager/main/install.sh)
```

安装完成：

```bash
ssmenu
```

### 对已有服务器的保护

如果检测到：

```text
/etc/shadowsocks-rust/config.json
```

已经存在，安装器不会覆盖现有配置、端口或密码。

如果检测到：

```text
/usr/local/bin/ssserver
```

已经存在，首次运行安装器也不会主动覆盖，之后可在菜单 `10` 或 `19` 手动更新。

## 管理菜单

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
19. 安装 / 重装 Shadowsocks Rust
20. 修复安装环境
21. 设置 IPv4 / IPv6 入站监听
0.  退出
```

## 路径

```text
/usr/local/bin/ssserver
/usr/local/bin/ssmenu
/usr/local/bin/ssupdate
/etc/shadowsocks-rust/config.json
/etc/systemd/system/shadowsocks-rust.service
/var/backups/shadowsocks-rust/
```

## Release 离线安装

```bash
tar -xzf SS-Rust-Manager-v1.1.2.tar.gz
cd SS-Rust-Manager-v1.1.2
bash install.sh
```

## 已验证/目标环境

- Debian 13
- Debian 12（全新安装及缺失文件修复需在 VPS 实测）
- systemd
- x86_64 / aarch64
- Shadowsocks Rust 官方 Release

## 安全

公开仓库不要上传真实 `config.json`、密码、私人密钥或节点配置。

`ssserver` 二进制不保存在本仓库；安装/更新时从官方 `shadowsocks/shadowsocks-rust` Release 下载。


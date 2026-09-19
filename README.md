# SS-Rust-Manager

Shadowsocks Rust 一键安装、更新及管理工具。

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
tar -xzf SS-Rust-Manager-v1.1.0.tar.gz
cd SS-Rust-Manager-v1.1.0
bash install.sh
```

## 已验证/目标环境

- Debian 13
- systemd
- x86_64 / aarch64
- Shadowsocks Rust 官方 Release

## 安全

公开仓库不要上传真实 `config.json`、密码、私人密钥或节点配置。

`ssserver` 二进制不保存在本仓库；安装/更新时从官方 `shadowsocks/shadowsocks-rust` Release 下载。

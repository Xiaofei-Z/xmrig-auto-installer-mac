# XMRig 自动安装脚本 for macOS

自动安装、配置和启动 XMRig 的脚本，专为 macOS（ARM64）设计。

## 功能特性

- ✅ 自动下载最新版 XMRig
- ✅ 自动解压并设置权限
- ✅ 自动创建优化的配置文件
- ✅ 支持 Unmineable 矿池
- ✅ 自动检查脚本更新
- ✅ 支持参数化运行

## 快速开始

### 一键安装并运行

```bash
# 下载并运行脚本
curl -L https://raw.githubusercontent.com/Xiaofei-Z/xmrig-auto-installer-mac/main/install.sh -o install.sh
chmod +x install.sh
./install.sh


### 新增无交互脚本（慎用）

# 默认：自动安装并立即启动
./install.sh

# 只安装，不启动
./install.sh --no-start

# 只下载文件
./install.sh --download

# 只创建配置文件
./install.sh --config

# 检查更新
./install.sh --update

# 显示帮助
./install.sh --help

### 一键运行命令（无交互）

# 下载脚本并直接运行（全自动无确认）
bash <(curl -s https://raw.githubusercontent.com/Xiaofei-Z/xmrig-auto-installer-mac/main/install2.sh)

# 或者
curl -L https://raw.githubusercontent.com/Xiaofei-Z/xmrig-auto-installer-mac/main/install2.sh | bash

#!/bin/bash

# XMRig 自动安装配置脚本 for macOS
# GitHub: https://github.com/Xiaofei-Z/xmrig-auto-installer-mac
set -e  # 遇到错误时退出脚本

# 配置信息
GITHUB_REPO="Xiaofei-Z/xmrig-auto-installer-mac"
SCRIPT_URL="https://raw.githubusercontent.com/${GITHUB_REPO}/main/install.sh"
CONFIG_FILE="config.json"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 打印状态消息
print_status() {
    echo -e "${GREEN}[+]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

print_error() {
    echo -e "${RED}[!]${NC} $1"
}

print_info() {
    echo -e "${BLUE}[*]${NC} $1"
}

print_input() {
    echo -e "${CYAN}[?]${NC} $1"
}

# 检查是否在 macOS 上运行
if [[ "$(uname)" != "Darwin" ]]; then
    print_error "此脚本仅适用于 macOS 系统"
    exit 1
fi

# 显示横幅
show_banner() {
    echo "╔══════════════════════════════════════════════════════════╗"
    echo "║               XMRig 自动安装配置脚本 for macOS           ║"
    echo "║           支持狗狗币(Dogecoin)挖矿 via Unmineable        ║"
    echo "║      GitHub: https://github.com/Xiaofei-Z/xmrig-auto-installer-mac       ║"
    echo "╚══════════════════════════════════════════════════════════╝"
    echo
}

# 获取用户钱包地址
get_wallet_address() {
    local wallet_address=""
    
    print_input "请输入您的狗狗币(Dogecoin)钱包地址："
    echo "示例: DNRt28b7MTjXyoJr6dA6B6SvWWscR11e1C"
    echo "注意: 地址应以 'D' 开头"
    echo
    
    while [[ -z "$wallet_address" ]]; do
        read -p "钱包地址: " wallet_address
        
        # 简单验证钱包地址格式
        if [[ -z "$wallet_address" ]]; then
            print_error "钱包地址不能为空"
            continue
        fi
        
        # 检查是否以 D 开头（标准狗狗币地址）
        if [[ ! "$wallet_address" =~ ^D ]]; then
            print_warning "警告：标准的狗狗币地址通常以 'D' 开头"
            read -p "确认使用此地址？(y/n): " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                wallet_address=""
                continue
            fi
        fi
        
        # 确认地址
        echo
        print_info "您输入的钱包地址: $wallet_address"
        read -p "确认正确？(y/n): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            wallet_address=""
        fi
    done
    
    echo "$wallet_address"
}

# 检测最新版本
detect_latest_version() {
    print_info "检测 XMRig 最新版本..."
    
    # 尝试从 GitHub API 获取最新版本
    local api_url="https://api.github.com/repos/xmrig/xmrig/releases/latest"
    local latest_version=""
    
    if command -v curl &> /dev/null; then
        latest_version=$(curl -s "$api_url" | grep '"tag_name":' | sed -E 's/.*"v?([^"]+)".*/\1/')
    fi
    
    # 如果无法获取，使用默认版本
    if [[ -z "$latest_version" ]] || [[ "$latest_version" == "null" ]]; then
        print_warning "无法获取最新版本，使用默认版本 6.25.0"
        latest_version="6.25.0"
    else
        print_status "检测到最新版本: $latest_version"
    fi
    
    echo "$latest_version"
}

# 检测系统架构并选择合适的版本
detect_architecture() {
    local arch=""
    
    case "$(uname -m)" in
        "arm64")
            arch="macos-arm64"
            print_status "检测到 ARM64 (Apple Silicon) 架构"
            ;;
        "x86_64")
            arch="macos-x64"
            print_status "检测到 x86_64 (Intel) 架构"
            ;;
        *)
            arch="macos-arm64"  # 默认使用 ARM64
            print_warning "未知架构，默认使用 ARM64 版本"
            ;;
    esac
    
    echo "$arch"
}

# 检查脚本更新
check_update() {
    print_info "检查脚本更新..."
    
    if ! command -v curl &> /dev/null; then
        print_warning "无法检查更新：curl 未安装"
        return
    fi
    
    local latest_script
    if latest_script=$(curl -s "$SCRIPT_URL" 2>/dev/null); then
        local current_hash
        local latest_hash
        current_hash=$(shasum -a 256 "$0" 2>/dev/null | cut -d' ' -f1)
        latest_hash=$(echo "$latest_script" | shasum -a 256 | cut -d' ' -f1)
        
        if [[ "$current_hash" != "$latest_hash" ]]; then
            print_warning "发现新版本的脚本！"
            echo "建议更新到最新版本："
            echo "  curl -L https://raw.githubusercontent.com/Xiaofei-Z/xmrig-auto-installer-mac/main/install.sh -o install.sh"
            echo "  chmod +x install.sh"
            echo
            sleep 2
        fi
    fi
}

# 检查依赖工具
check_dependencies() {
    print_status "检查系统依赖..."
    
    local deps=("curl" "tar")
    local missing_deps=()
    
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            missing_deps+=("$dep")
        fi
    done
    
    if [ ${#missing_deps[@]} -gt 0 ]; then
        print_error "缺少以下依赖：${missing_deps[*]}"
        echo "正在尝试安装缺少的依赖..."
        
        # 尝试使用 Homebrew 安装
        if command -v brew &> /dev/null; then
            print_info "使用 Homebrew 安装依赖..."
            brew install "${missing_deps[@]}"
        else
            print_error "请先安装 Homebrew，然后运行："
            echo "  /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
            echo "  brew install ${missing_deps[*]}"
            exit 1
        fi
    fi
    
    print_status "依赖检查完成"
}

# 清理旧文件
cleanup_old_files() {
    local pattern="xmrig-*-macos-*.tar.gz"
    
    for file in $pattern; do
        if [ -f "$file" ]; then
            print_status "删除旧的压缩包: $file"
            rm -f "$file"
        fi
    done
    
    # 删除旧的解压目录
    for dir in xmrig-*; do
        if [ -d "$dir" ] && [[ "$dir" != "xmrig-auto-installer-mac" ]]; then
            print_status "删除旧的解压目录: $dir"
            rm -rf "$dir"
        fi
    done
}

# 下载 XMRig
download_xmrig() {
    local version="$1"
    local arch="$2"
    local tar_file="xmrig-${version}-${arch}.tar.gz"
    local download_url="https://github.com/xmrig/xmrig/releases/download/v${version}/${tar_file}"
    
    print_status "下载 XMRig ${version} (${arch})..."
    
    if ! curl -L "$download_url" -o "$tar_file"; then
        print_error "下载失败，尝试备用下载方式..."
        
        # 尝试不带 v 前缀的 URL
        download_url="https://github.com/xmrig/xmrig/releases/download/${version}/${tar_file}"
        if ! curl -L "$download_url" -o "$tar_file"; then
            print_error "下载失败，请检查："
            echo "  1. 网络连接"
            echo "  2. 版本是否仍然可用"
            echo "  3. GitHub 访问状态"
            exit 1
        fi
    fi
    
    if [ ! -f "$tar_file" ]; then
        print_error "下载的文件不存在"
        exit 1
    fi
    
    # 验证下载文件
    local file_size
    file_size=$(stat -f%z "$tar_file" 2>/dev/null)
    
    if [ "$file_size" -lt 1000000 ]; then  # 小于 1MB 可能是错误的
        print_error "下载的文件可能不完整 (大小: ${file_size} 字节)"
        rm -f "$tar_file"
        exit 1
    fi
    
    print_status "下载完成 ($(($file_size/1024/1024)) MB)"
    echo "$tar_file"
}

# 解压文件
extract_xmrig() {
    local tar_file="$1"
    
    print_status "解压文件: $tar_file..."
    
    if ! tar -xzf "$tar_file"; then
        print_error "解压失败"
        exit 1
    fi
    
    # 获取解压后的目录名
    local extract_dir=$(tar -tzf "$tar_file" | head -1 | cut -f1 -d"/")
    
    if [ ! -d "$extract_dir" ]; then
        print_error "解压目录不存在"
        exit 1
    fi
    
    cd "$extract_dir" || exit 1
    print_status "解压完成，当前目录: $(pwd)"
    
    echo "$extract_dir"
}

# 创建配置文件
create_config() {
    local wallet_address="$1"
    
    print_status "创建配置文件..."
    
    cat > "$CONFIG_FILE" << EOF
{
    "api": {
        "id": null,
        "worker-id": null
    },
    "http": {
        "enabled": false,
        "host": "127.0.0.1",
        "port": 0,
        "access-token": null,
        "restricted": true
    },
    "autosave": true,
    "background": false,
    "colors": true,
    "title": true,
    "randomx": {
        "init": -1,
        "init-avx2": -1,
        "mode": "auto",
        "1gb-pages": false,
        "rdmsr": true,
        "wrmsr": false,
        "cache_qos": false,
        "numa": true,
        "scratchpad_prefetch_mode": 1
    },
    "cpu": {
        "enabled": true,
        "huge-pages": true,
        "huge-pages-jit": false,
        "hw-aes": null,
        "priority": null,
        "memory-pool": false,
        "yield": true,
        "argon2-impl": null,
        "argon2": [0, 1, 2, 3, 4, 5, 6, 7, 8, 9],
        "cn": [0, 1, 2, 3, 4, 5, 6, 7, 8, 9],
        "cn-heavy": [0, 1, 2, 3, 4, 5, 6, 7, 8, 9],
        "cn-lite": [0, 1, 2, 3, 4, 5, 6, 7, 8, 9],
        "cn-pico": [0, 1, 2, 3, 4, 5, 6, 7, 8, 9],
        "cn/upx2": [0, 1, 2, 3, 4, 5, 6, 7, 8, 9],
        "ghostrider": [
            [8, 0],
            [8, 1],
            [8, 2],
            [8, 3],
            [8, 4],
            [8, 5],
            [8, 6],
            [8, 7],
            [8, 8],
            [8, 9]
        ],
        "rx": [0, 1, 2, 3, 4, 5, 6, 7, 8, 9],
        "rx/wow": [0, 1, 2, 3, 4, 5, 6, 7, 8, 9],
        "cn-lite/0": false,
        "cn/0": false,
        "rx/arq": "rx/wow"
    },
    "opencl": {
        "enabled": false,
        "cache": true,
        "loader": null,
        "cn-lite/0": false,
        "cn/0": false
    },
    "cuda": {
        "enabled": false,
        "loader": null,
        "cn-lite/0": false,
        "cn/0": false
    },
    "log-file": null,
    "donate-level": 1,
    "donate-over-proxy": 1,
    "pools": [
        {
            "algo": null,
            "coin": null,
            "url": "rx.unmineable.com:3333",
            "user": "DOGE:${wallet_address}.xmrig-auto-installer",
            "pass": "x",
            "rig-id": null,
            "nicehash": false,
            "keepalive": true,
            "enabled": true,
            "tls": false,
            "sni": false,
            "tls-fingerprint": null,
            "daemon": false,
            "socks5": null,
            "self-select": null,
            "submit-to-origin": false
        }
    ],
    "retries": 5,
    "retry-pause": 5,
    "print-time": 60,
    "syslog": false,
    "tls": {
        "enabled": false,
        "protocols": null,
        "cert": null,
        "cert_key": null,
        "ciphers": null,
        "ciphersuites": null,
        "dhparam": null
    },
    "dns": {
        "ip_version": 0,
        "ttl": 30
    },
    "user-agent": null,
    "verbose": 0,
    "watch": true,
    "pause-on-battery": true,
    "pause-on-active": false
}
EOF
    
    if [ ! -f "$CONFIG_FILE" ]; then
        print_error "配置文件创建失败"
        exit 1
    fi
    
    print_status "配置文件已创建"
    
    # 显示配置摘要
    echo
    print_info "配置摘要："
    echo "  矿池: rx.unmineable.com:3333"
    echo "  钱包地址: DOGE:${wallet_address}"
    echo "  矿工名称: xmrig-auto-installer"
    echo "  捐赠比例: 1%"
    echo "  节电模式: 检测到电池时暂停挖矿"
    echo
    print_warning "注意：您可以编辑 config.json 修改配置参数"
}

# 设置可执行权限
set_permissions() {
    print_status "设置可执行权限..."
    
    if [ -f "xmrig" ]; then
        chmod +x xmrig
        print_status "可执行权限已设置"
    else
        print_error "xmrig 可执行文件未找到"
        exit 1
    fi
}

# 显示挖矿信息
show_mining_info() {
    local wallet_address="$1"
    
    echo "╔══════════════════════════════════════════════════════════╗"
    echo "║                    挖矿信息汇总                          ║"
    echo "╠══════════════════════════════════════════════════════════╣"
    echo "║ 钱包地址: DOGE:${wallet_address}"
    echo "║ 矿池地址: rx.unmineable.com:3333"
    echo "║ 矿工名称: xmrig-auto-installer"
    echo "║ 捐赠比例: 1% (支持 XMRig 开发)"
    echo "║ 算法: RandomX (用于狗狗币挖矿)"
    echo "╠══════════════════════════════════════════════════════════╣"
    echo "║             在浏览器中查看挖矿状态：                     ║"
    echo "║ https://unmineable.com/coins/DOGE/address/${wallet_address}"
    echo "╚══════════════════════════════════════════════════════════╝"
    echo
}

# 启动 XMRig
start_xmrig() {
    local wallet_address="$1"
    
    print_status "启动狗狗币挖矿程序..."
    
    # 显示挖矿信息
    show_mining_info "$wallet_address"
    
    echo "══════════════════════════════════════════════════════════"
    echo "   XMRig 开始运行 - 狗狗币挖矿"
    echo "   ⚡ 正在连接到矿池..."
    echo "   💻 CPU 使用率将会增加"
    echo "   🔋 使用电池时会自动暂停"
    echo "   🛑 按 Ctrl+C 停止挖矿"
    echo "══════════════════════════════════════════════════════════"
    
    # 检查配置
    if [ ! -f "$CONFIG_FILE" ]; then
        print_error "配置文件不存在"
        exit 1
    fi
    
    # 显示启动命令
    echo
    print_info "启动命令：./xmrig --config=config.json"
    print_info "详细日志：./xmrig --config=config.json --verbose"
    echo "══════════════════════════════════════════════════════════"
    echo
    print_warning "注意：首次连接可能需要几分钟时间"
    print_warning "挖矿收益将发送到您的狗狗币钱包"
    
    # 等待 3 秒让用户查看信息
    sleep 3
    
    # 启动 xmrig
    ./xmrig --config=config.json
}

# 显示帮助信息
show_help() {
    echo "用法: $0 [选项]"
    echo
    echo "选项:"
    echo "  -h, --help      显示此帮助信息"
    echo "  -d, --download  仅下载，不启动"
    echo "  -c, --config    仅创建配置文件"
    echo "  -u, --update    检查脚本更新"
    echo "  -n, --no-start  安装但不启动"
    echo "  -w ADDRESS, --wallet ADDRESS  指定钱包地址"
    echo
    echo "示例:"
    echo "  $0                           完整安装并启动"
    echo "  $0 --wallet YOUR_DOGE_ADDR   使用指定地址安装"
    echo "  $0 --download                仅下载和解压"
    echo "  $0 --config                  仅创建配置文件"
    echo "  $0 --no-start                安装但不启动"
}

# 主函数
main() {
    local action="full"
    local start_mining=true
    local wallet_address=""
    
    # 解析参数
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -d|--download)
                action="download"
                start_mining=false
                shift
                ;;
            -c|--config)
                action="config"
                start_mining=false
                shift
                ;;
            -u|--update)
                check_update
                exit 0
                ;;
            -n|--no-start)
                start_mining=false
                shift
                ;;
            -w|--wallet)
                if [[ -n "$2" ]]; then
                    wallet_address="$2"
                    shift 2
                else
                    print_error "--wallet 选项需要参数"
                    exit 1
                fi
                ;;
            --wallet=*)
                wallet_address="${1#*=}"
                shift
                ;;
            *)
                print_error "未知选项: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    show_banner
    
    # 检查更新
    check_update
    
    # 获取钱包地址
    if [[ -z "$wallet_address" ]]; then
        wallet_address=$(get_wallet_address)
    fi
    
    # 检测最新版本和架构
    local version=$(detect_latest_version)
    local arch=$(detect_architecture)
    
    case $action in
        download)
            check_dependencies
            cleanup_old_files
            download_xmrig "$version" "$arch"
            print_status "下载完成！文件: xmrig-${version}-${arch}.tar.gz"
            ;;
        config)
            create_config "$wallet_address"
            print_status "配置文件已创建: $(pwd)/config.json"
            ;;
        full)
            check_dependencies
            cleanup_old_files
            
            # 下载
            local tar_file=$(download_xmrig "$version" "$arch")
            
            # 解压
            local extract_dir=$(extract_xmrig "$tar_file")
            
            # 创建配置
            create_config "$wallet_address"
            
            # 设置权限
            set_permissions
            
            echo
            print_status "狗狗币挖矿程序安装完成！"
            echo
            echo "版本信息:"
            echo "  XMRig 版本: $version"
            echo "  系统架构: $arch"
            echo "  安装目录: $(pwd)"
            echo "  配置文件: $(pwd)/config.json"
            echo
            echo "手动启动命令:"
            echo "  ./xmrig --config=config.json"
            echo
            echo "查看挖矿状态:"
            echo "  https://unmineable.com/coins/DOGE/address/${wallet_address}"
            echo
            
            if [ "$start_mining" = true ]; then
                start_xmrig "$wallet_address"
            else
                print_info "安装完成，但未启动挖矿。"
                echo "要启动挖矿，请运行:"
                echo "  cd $(pwd)"
                echo "  ./xmrig --config=config.json"
            fi
            ;;
    esac
}

# 运行主函数
main "$@"

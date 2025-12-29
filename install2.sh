#!/bin/bash

# XMRig 自动安装配置脚本 for macOS
# GitHub: https://github.com/YOUR_USERNAME/xmrig-auto-installer-mac
set -e  # 遇到错误时退出脚本

# 配置信息
VERSION="6.25.0"
ARCH="macos-arm64"
GITHUB_REPO="Xiaofei-Z/xmrig-auto-installer-mac"
SCRIPT_URL="https://raw.githubusercontent.com/${GITHUB_REPO}/main/install.sh"
TAR_FILE="xmrig-${VERSION}-${ARCH}.tar.gz"
DOWNLOAD_URL="https://github.com/xmrig/xmrig/releases/download/v${VERSION}/${TAR_FILE}"
EXTRACT_DIR="xmrig-${VERSION}"
CONFIG_FILE="config.json"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

# 检查是否在 macOS 上运行
if [[ "$(uname)" != "Darwin" ]]; then
    print_error "此脚本仅适用于 macOS 系统"
    exit 1
fi

# 检查是否为 ARM64 架构
if [[ "$(uname -m)" != "arm64" ]]; then
    print_warning "检测到非 ARM64 架构，使用 ARM64 版本可能无法正常运行"
    # 这里不再询问确认，直接继续执行
fi

# 显示横幅
show_banner() {
    echo "=========================================="
    echo "  XMRig 自动安装配置脚本 for macOS"
    echo "  版本: ${VERSION}"
    echo "  架构: ${ARCH}"
    echo "  GitHub: https://github.com/${GITHUB_REPO}"
    echo "=========================================="
    echo
}

# 检查脚本更新
check_update() {
    print_info "检查更新..."
    
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
            echo "当前脚本可能不是最新版本。"
            echo "请从 GitHub 获取最新版本："
            echo "  curl -L https://raw.githubusercontent.com/${GITHUB_REPO}/main/install.sh -o install.sh"
            echo
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
            for dep in "${missing_deps[@]}"; do
                brew install "$dep"
            done
        else
            print_error "请先安装 Homebrew，然后运行："
            echo "  brew install ${missing_deps[*]}"
            exit 1
        fi
    fi
    
    print_status "依赖检查完成"
}

# 清理旧文件
cleanup_old_files() {
    if [ -f "$TAR_FILE" ]; then
        print_status "删除旧的压缩包..."
        rm -f "$TAR_FILE"
    fi
    
    if [ -d "$EXTRACT_DIR" ]; then
        print_status "删除旧的解压目录..."
        rm -rf "$EXTRACT_DIR"
    fi
}

# 下载 XMRig
download_xmrig() {
    print_status "下载 XMRig ${VERSION}..."
    
    if ! curl -L "$DOWNLOAD_URL" -o "$TAR_FILE"; then
        print_error "下载失败，请检查："
        echo "  1. 网络连接"
        echo "  2. URL 是否正确: $DOWNLOAD_URL"
        echo "  3. 版本是否仍然可用"
        exit 1
    fi
    
    if [ ! -f "$TAR_FILE" ]; then
        print_error "下载的文件不存在"
        exit 1
    fi
    
    # 验证下载文件
    local file_size
    file_size=$(stat -f%z "$TAR_FILE" 2>/dev/null)
    
    if [ "$file_size" -lt 1000000 ]; then  # 小于 1MB 可能是错误的
        print_error "下载的文件可能不完整"
        exit 1
    fi
    
    print_status "下载完成 ($(($file_size/1024/1024)) MB)"
}

# 解压文件
extract_xmrig() {
    print_status "解压文件..."
    
    if ! tar -xzf "$TAR_FILE"; then
        print_error "解压失败"
        exit 1
    fi
    
    if [ ! -d "$EXTRACT_DIR" ]; then
        print_error "解压目录不存在"
        exit 1
    fi
    
    cd "$EXTRACT_DIR" || exit 1
    print_status "解压完成，当前目录: $(pwd)"
}

# 创建配置文件
create_config() {
    print_status "创建配置文件..."
    
    cat > "$CONFIG_FILE" << 'EOF'
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
            "url": "rx.unmineable.com",
            "user": "DOGE:DTiQZt5t2iB7agoGbzrFJYMFePWJ8yNkrx.WJW_ZX",
            "pass": "x",
            "rig-id": null,
            "nicehash": false,
            "keepalive": false,
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
    "pause-on-battery": false,
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
    echo "  矿池: rx.unmineable.com"
    echo "  钱包地址: DOGE:DNRt28b7MTjXyoJr6dA6B6SvWWscR11e1C.kuskyfei"
    echo "  捐赠比例: 1%"
    echo
    print_warning "注意：您可以编辑 config.json 修改钱包地址"
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

# 启动 XMRig
start_xmrig() {
    print_status "启动 XMRig..."
    echo "=========================================="
    echo "   XMRig 开始运行"
    echo "   挖矿地址: DOGE:DNRt28b7MTjXyoJr6dA6B6SvWWscR11e1C.kuskyfei"
    echo "   矿池: rx.unmineable.com"
    echo "   按 Ctrl+C 停止运行"
    echo "=========================================="
    
    # 检查配置
    if [ ! -f "$CONFIG_FILE" ]; then
        print_error "配置文件不存在"
        exit 1
    fi
    
    # 显示启动信息
    echo
    print_info "启动命令：./xmrig --config=config.json"
    echo "=========================================="
    
    # 启动 xmrig
    ./xmrig --config=config.json
}

# 显示帮助信息
show_help() {
    echo "用法: $0 [选项]"
    echo
    echo "选项:"
    echo "  -h, --help     显示此帮助信息"
    echo "  -d, --download 仅下载，不启动"
    echo "  -c, --config   仅创建配置文件"
    echo "  -u, --update   检查脚本更新"
    echo "  -n, --no-start 安装但不启动"
    echo
    echo "示例:"
    echo "  $0              完整安装并启动（默认）"
    echo "  $0 --download   仅下载和解压"
    echo "  $0 --config     仅创建配置文件"
    echo "  $0 --no-start   安装但不启动"
}

# 主函数
main() {
    local action="full"
    local start_mining=true
    
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
    
    case $action in
        download)
            check_dependencies
            cleanup_old_files
            download_xmrig
            extract_xmrig
            set_permissions
            print_status "下载完成！文件位置: $(pwd)"
            ;;
        config)
            create_config
            print_status "配置文件已创建: $(pwd)/config.json"
            ;;
        full)
            check_dependencies
            cleanup_old_files
            download_xmrig
            extract_xmrig
            create_config
            set_permissions
            
            echo
            print_status "安装完成！"
            echo
            echo "文件位置: $(pwd)"
            echo "配置文件: $(pwd)/config.json"
            echo
            echo "手动启动命令:"
            echo "  ./xmrig --config=config.json"
            echo
            echo "查看帮助:"
            echo "  ./xmrig --help"
            echo
            
            if [ "$start_mining" = true ]; then
                start_xmrig
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

#!/bin/bash
# RDK X5 DFR0550-V1 5寸DSI屏一键安装脚本
# 使用方法: sudo ./install.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}====================================${NC}"
echo -e "${GREEN}  RDK X5 DSI 5寸屏适配安装脚本${NC}"
echo -e "${GREEN}  适用于 DFRobot DFR0550-V1${NC}"
echo -e "${GREEN}====================================${NC}"
echo ""

# 检查是否以root权限运行
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}错误: 请使用 sudo 运行此脚本${NC}"
    exit 1
fi

# 检查系统是否为 RDK X5
if ! grep -q "rdkx5" /proc/device-tree/model 2>/dev/null; then
    echo -e "${YELLOW}警告: 未检测到 RDK X5 设备，是否继续? (y/n)${NC}"
    read -r response
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

echo -e "${YELLOW}[1/5] 检查依赖...${NC}"

# 检查 dtc 是否安装
if ! command -v dtc > /dev/null 2>&1; then
    echo -e "${RED}错误: 未找到 dtc (设备树编译器)${NC}"
    echo "请安装: sudo apt-get install device-tree-compiler"
    exit 1
fi

echo -e "${YELLOW}[2/5] 编译设备树 overlay...${NC}"

# 编译 DTS 为 DTBO
if [ -f "$SCRIPT_DIR/dsi-dfrobot-v1.dts" ]; then
    dtc -I dts -O dtb -o "$SCRIPT_DIR/dsi-dfrobot-v1.dtbo" "$SCRIPT_DIR/dsi-dfrobot-v1.dts" 2>&1 || {
        echo -e "${YELLOW}编译警告 (通常可忽略)...${NC}"
    }
else
    echo -e "${RED}错误: 找不到 dsi-dfrobot-v1.dts${NC}"
    exit 1
fi

echo -e "${YELLOW}[3/5] 安装设备树 overlay...${NC}"

# 复制 dtbo 到 /boot/overlays/
cp "$SCRIPT_DIR/dsi-dfrobot-v1.dtbo" /boot/overlays/
chmod 644 /boot/overlays/dsi-dfrobot-v1.dtbo

# 配置 config.txt
CONFIG_FILE="/boot/config.txt"
if [ -f "$CONFIG_FILE" ]; then
    # 备份原配置
    cp "$CONFIG_FILE" "$CONFIG_FILE.backup.$(date +%Y%m%d%H%M%S)"

    # 移除旧的 dsi overlay 配置
    sed -i '/^dtoverlay=dsi-/d' "$CONFIG_FILE"

    # 添加新的配置
    echo "dtoverlay=dsi-dfrobot-v1" >> "$CONFIG_FILE"

    echo -e "${GREEN}  已配置: dtoverlay=dsi-dfrobot-v1${NC}"
else
    echo "dtoverlay=dsi-dfrobot-v1" > "$CONFIG_FILE"
    echo -e "${GREEN}  已创建配置: $CONFIG_FILE${NC}"
fi

echo -e "${YELLOW}[4/5] 配置背光自动开启...${NC}"

# 配置 rc.local
RC_LOCAL="/etc/rc.local"
if [ -f "$RC_LOCAL" ]; then
    # 备份原配置
    cp "$RC_LOCAL" "$RC_LOCAL.backup.$(date +%Y%m%d%H%M%S)"

    # 移除旧的背光配置
    sed -i '/panel_backlight/d' "$RC_LOCAL"

    # 在 exit 0 之前添加背光配置
    sed -i '/^exit 0/i echo 200 > /sys/class/backlight/panel_backlight/brightness 2>/dev/null || true' "$RC_LOCAL"

    echo -e "${GREEN}  已更新: $RC_LOCAL${NC}"
else
    # 创建新的 rc.local
    cat > "$RC_LOCAL" <> 'EOF'
#!/bin/bash -e
# RDK X5 DSI 5寸屏背光配置

# 开启DSI面板背光（亮度范围 0-255）
echo 200 > /sys/class/backlight/panel_backlight/brightness 2>/dev/null || true

exit 0
EOF
    chmod +x "$RC_LOCAL"
    echo -e "${GREEN}  已创建: $RC_LOCAL${NC}"
fi

echo -e "${YELLOW}[5/5] 配置 X11 显示...${NC}"

# 确定当前用户（非root）
CURRENT_USER=${SUDO_USER:-$USER}
if [ "$CURRENT_USER" = "root" ]; then
    # 尝试从 HOME 目录推断用户
    for user in sunrise ubuntu pi; do
        if [ -d "/home/$user" ]; then
            CURRENT_USER="$user"
            break
        fi
    done
fi

echo ""
echo "请选择 X11 显示配置方案:"
echo "  1) LightDM 自动修复 (推荐，解决重启黑屏问题)"
echo "  2) 用户配置文件 (~/.xprofile)"
echo "  3) 跳过 X11 配置"
read -r -p "请输入选项 [1-3]: " x11_choice

case "$x11_choice" in
    1)
        echo -e "${YELLOW}  安装 LightDM 自动修复脚本...${NC}"
        cp "$SCRIPT_DIR/lightdm-session-fix.sh" /usr/local/bin/
        chmod +x /usr/local/bin/lightdm-session-fix.sh

        # 创建 LightDM 配置
        mkdir -p /etc/lightdm/lightdm.conf.d/
        cat > /etc/lightdm/lightdm.conf.d/99-dsi-session-fix.conf << 'EOF'
[Seat:*]
session-setup-script=/usr/local/bin/lightdm-session-fix.sh
EOF
        echo -e "${GREEN}  已配置: LightDM session-setup-script${NC}"
        ;;
    2)
        USER_HOME="/home/$CURRENT_USER"
        XPROFILE="$USER_HOME/.xprofile"

        if [ -f "$SCRIPT_DIR/xprofile" ]; then
            cp "$SCRIPT_DIR/xprofile" "$XPROFILE"
            chmod +x "$XPROFILE"
            chown "$CURRENT_USER:$CURRENT_USER" "$XPROFILE"
            echo -e "${GREEN}  已配置: ~/.xprofile (用户: $CURRENT_USER)${NC}"
        else
            echo -e "${YELLOW}  警告: 未找到 xprofile 模板，跳过 X11 配置${NC}"
        fi
        ;;
    3)
        echo -e "${YELLOW}  跳过 X11 配置${NC}"
        ;;
    *)
        echo -e "${YELLOW}  无效选项，使用默认方案 (LightDM)...${NC}"
        cp "$SCRIPT_DIR/lightdm-session-fix.sh" /usr/local/bin/
        chmod +x /usr/local/bin/lightdm-session-fix.sh
        mkdir -p /etc/lightdm/lightdm.conf.d/
        cat > /etc/lightdm/lightdm.conf.d/99-dsi-session-fix.conf << 'EOF'
[Seat:*]
session-setup-script=/usr/local/bin/lightdm-session-fix.sh
EOF
        ;;
esac

echo ""
echo -e "${GREEN}====================================${NC}"
echo -e "${GREEN}  安装完成!${NC}"
echo -e "${GREEN}====================================${NC}"
echo ""
echo "请执行以下操作："
echo ""
echo "  1. 重启系统: sudo reboot"
echo "  2. 重启后检查显示: xrandr --listmonitors"
echo ""
echo "显示切换命令:"
echo "  - 切换到5寸屏: xrandr --output HDMI-1 --off; xrandr --output DSI-1 --auto"
echo "  - 切换到HDMI:  xrandr --output DSI-1 --off; xrandr --output HDMI-1 --auto"
echo "  - 调整背光:    echo 0-255 > /sys/class/backlight/panel_backlight/brightness"
echo ""
echo -e "${YELLOW}注意: RDK X5 只能同时驱动一个显示 (DSI 或 HDMI)${NC}"
echo ""

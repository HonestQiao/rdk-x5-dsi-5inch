#!/bin/bash
# RDK X5 DFR0550-V1 5寸DSI屏一键安装脚本
# 使用方法: sudo ./install.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

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

# 获取实际用户名（非root）
REAL_USER=${SUDO_USER:-$USER}
if [ "$REAL_USER" = "root" ]; then
    # 尝试推断普通用户
    for user in sunrise ubuntu pi; do
        if [ -d "/home/$user" ]; then
            REAL_USER="$user"
            break
        fi
    done
fi

echo -e "${YELLOW}[1/6] 检查依赖...${NC}"

# 检查必要文件
if [ ! -f "$SCRIPT_DIR/dsi-dfrobot-v1.dtbo" ]; then
    if [ -f "$SCRIPT_DIR/dsi-dfrobot-v1.dts" ]; then
        echo -e "${YELLOW}编译设备树 overlay...${NC}"
        if command -v dtc >/dev/null 2>&1; then
            dtc -I dts -O dtb -o "$SCRIPT_DIR/dsi-dfrobot-v1.dtbo" "$SCRIPT_DIR/dsi-dfrobot-v1.dts" 2>&1 || {
                echo -e "${YELLOW}编译警告 (通常可忽略)...${NC}"
            }
        else
            echo -e "${RED}错误: 未找到 dtc，且 .dtbo 文件不存在${NC}"
            exit 1
        fi
    else
        echo -e "${RED}错误: 找不到 dsi-dfrobot-v1.dtbo 或 dsi-dfrobot-v1.dts${NC}"
        exit 1
    fi
fi

echo -e "${YELLOW}[2/6] 安装设备树 overlay...${NC}"

# 复制 dtbo 到 /boot/overlays/
cp "$SCRIPT_DIR/dsi-dfrobot-v1.dtbo" /boot/overlays/
chmod 644 /boot/overlays/dsi-dfrobot-v1.dtbo

# 配置 config.txt
CONFIG_FILE="/boot/config.txt"
if [ -f "$CONFIG_FILE" ]; then
    cp "$CONFIG_FILE" "$CONFIG_FILE.backup.$(date +%Y%m%d%H%M%S)"
    # 移除旧的 dsi overlay 配置
    sed -i '/^dtoverlay=dsi-/d' "$CONFIG_FILE"
    # 添加新的配置
    echo "dtoverlay=dsi-dfrobot-v1" >> "$CONFIG_FILE"
else
    echo "dtoverlay=dsi-dfrobot-v1" > "$CONFIG_FILE"
fi
echo -e "${GREEN}  已配置: dtoverlay=dsi-dfrobot-v1${NC}"

echo -e "${YELLOW}[3/6] 安装 LightDM 脚本...${NC}"

# 复制脚本
cp "$SCRIPT_DIR/dsi-fix.sh" /usr/local/bin/
cp "$SCRIPT_DIR/dsi-session-fix.sh" /usr/local/bin/
chmod +x /usr/local/bin/dsi-fix.sh /usr/local/bin/dsi-session-fix.sh

# 创建 LightDM 配置
mkdir -p /etc/lightdm/lightdm.conf.d
cat > /etc/lightdm/lightdm.conf.d/99-dsi-fix.conf << 'EOF'
[Seat:*]
display-setup-script=/usr/local/bin/dsi-fix.sh
session-setup-script=/usr/local/bin/dsi-session-fix.sh
EOF

echo -e "${GREEN}  已配置 LightDM 脚本${NC}"

echo -e "${YELLOW}[4/6] 配置 sudo 权限...${NC}"

# 创建 sudoers 规则（免密码设置背光）
cat > /etc/sudoers.d/99-dsi-backlight << EOF
$REAL_USER ALL=(ALL) NOPASSWD: /bin/tee /sys/class/backlight/panel_backlight/brightness
$REAL_USER ALL=(ALL) NOPASSWD: /usr/bin/tee /sys/class/backlight/panel_backlight/brightness
EOF
chmod 440 /etc/sudoers.d/99-dsi-backlight

echo -e "${GREEN}  已配置 sudo 权限${NC}"

echo -e "${YELLOW}[5/6] 删除冲突配置...${NC}"

# 删除 ~/.xprofile（如果存在）
if [ -f "/home/$REAL_USER/.xprofile" ]; then
    mv "/home/$REAL_USER/.xprofile" "/home/$REAL_USER/.xprofile.backup.$(date +%Y%m%d%H%M%S)"
    echo -e "${GREEN}  已备份并删除 ~/.xprofile${NC}"
fi

# 清理可能冲突的 rc.local 配置
RC_LOCAL="/etc/rc.local"
if [ -f "$RC_LOCAL" ]; then
    # 备份原配置
    cp "$RC_LOCAL" "$RC_LOCAL.backup.$(date +%Y%m%d%H%M%S)" 2>/dev/null || true
fi

echo -e "${YELLOW}[6/6] 清理完成...${NC}"
echo -e "${GREEN}  安装准备就绪${NC}"

echo ""
echo -e "${GREEN}====================================${NC}"
echo -e "${GREEN}  安装完成!${NC}"
echo -e "${GREEN}====================================${NC}"
echo ""
echo "请执行: sudo reboot"
echo ""
echo "重启后:"
echo "  - 5寸屏应自动显示桌面"
echo "  - 分辨率为 800x480"
echo "  - 触摸应正常工作"
echo ""
echo "显示切换命令:"
echo "  xrandr --output HDMI-1 --off && xrandr --output DSI-1 --auto    # 切换到DSI"
echo "  xrandr --output DSI-1 --off && xrandr --output HDMI-1 --auto     # 切换到HDMI"
echo "  echo 200 | sudo tee /sys/class/backlight/panel_backlight/brightness  # 设置背光"
echo ""
echo -e "${YELLOW}注意: RDK X5 只能同时驱动一个显示 (DSI 或 HDMI)${NC}"
echo ""

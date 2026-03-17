#!/bin/bash
# LightDM session-setup-script
# 用于自动修复 DSI 屏幕初始化问题
# 配置方法：
#   sudo cp lightdm-session-fix.sh /usr/local/bin/
#   sudo tee /etc/lightdm/lightdm.conf.d/99-dsi-session-fix.conf << 'EOF'
#   [Seat:*]
#   session-setup-script=/usr/local/bin/lightdm-session-fix.sh
#   EOF

# 等待桌面环境启动
sleep 4

# 开启背光
echo 200 > /sys/class/backlight/panel_backlight/brightness 2>/dev/null || true

# 使用 sunrise 用户执行 xrandr（必须用用户身份，sudo 不生效）
sudo -u sunrise bash -c "export DISPLAY=:0; xrandr --output DSI-1 --off 2>/dev/null || true"
sleep 0.5
sudo -u sunrise bash -c "export DISPLAY=:0; xrandr --output DSI-1 --auto 2>/dev/null || true"
sudo -u sunrise bash -c "export DISPLAY=:0; xrandr --output DSI-1 --mode 800x480 --primary 2>/dev/null || true"

exit 0

#!/bin/bash
# LightDM session-setup-script: 用户登录后执行

export DISPLAY=:0

# 等待桌面环境启动
sleep 3

# 确保背光开启（以防万一）
sudo sh -c "echo 200 > /sys/class/backlight/panel_backlight/brightness" 2>/dev/null || true

# 重新配置DSI显示（原生800x480，无缩放）
xrandr --output DSI-1 --off 2>/dev/null || true
sleep 0.5
xrandr --output DSI-1 --auto 2>/dev/null || true
xrandr --output DSI-1 --mode 800x480 --primary 2>/dev/null || true

exit 0

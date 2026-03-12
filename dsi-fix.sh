#!/bin/bash
# LightDM display-setup-script: X11启动后、显示登录界面前执行

export DISPLAY=:0

# 等待X11完全启动
sleep 2

# 开启背光（使用sudo）
sudo sh -c "echo 200 > /sys/class/backlight/panel_backlight/brightness" 2>/dev/null || true

# 初始化解锁DSI显示（原生800x480，无缩放）
xrandr --output DSI-1 --off 2>/dev/null || true
sleep 0.5
xrandr --output DSI-1 --auto 2>/dev/null || true
xrandr --output DSI-1 --mode 800x480 --primary 2>/dev/null || true

exit 0

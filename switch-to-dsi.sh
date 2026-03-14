#!/bin/bash
# 切换到5寸DSI屏

export DISPLAY=${DISPLAY:-:0}

# 关闭HDMI
xrandr --output HDMI-1 --off 2>/dev/null

# 开启DSI并修正比例
xrandr --output DSI-1 --mode 800x480 --scale 1.067x1.0 --primary 2>/dev/null

# 设置背光
echo 200 > /sys/class/backlight/panel_backlight/brightness 2>/dev/null

echo "已切换到5寸DSI屏"

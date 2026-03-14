#!/bin/bash
# 切换到HDMI显示器

export DISPLAY=${DISPLAY:-:0}

# 关闭DSI
xrandr --output DSI-1 --off 2>/dev/null

# 开启HDMI
xrandr --output HDMI-1 --auto 2>/dev/null

echo "已切换到HDMI显示器"

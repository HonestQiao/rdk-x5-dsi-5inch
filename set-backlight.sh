#!/bin/bash
# 设置背光亮度
# 用法: ./set-backlight.sh [0-255]

BRIGHTNESS=${1:-200}

if [ "$BRIGHTNESS" -lt 0 ] || [ "$BRIGHTNESS" -gt 255 ]; then
    echo "错误: 亮度值必须在 0-255 之间"
    echo "用法: $0 [0-255]"
    exit 1
fi

echo $BRIGHTNESS > /sys/class/backlight/panel_backlight/brightness
echo "背光亮度已设置为: $BRIGHTNESS"

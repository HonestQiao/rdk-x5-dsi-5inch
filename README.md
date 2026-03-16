# RDK X5 DSI 5寸屏适配指南

适用于 DFRobot DFR0550-V1 5寸 DSI 触摸屏（800×480分辨率）

## 硬件信息

- **屏幕型号**: DFRobot DFR0550-V1
- **分辨率**: 800×480
- **接口**: MIPI DSI
- **触控**: 5点电容触控 (ft5406)
- **背光控制**: 支持 (panel_backlight)

## 文件说明

| 文件 | 说明 |
|------|------|
| `dsi-dfrobot-v1.dts` | 设备树 overlay 源码 |
| `dsi-dfrobot-v1.dtbo` | 编译后的设备树 overlay（二进制） |
| `install.sh` | 一键安装脚本 |
| `xprofile` | X11 显示配置文件 |
| `rc.local` | 系统启动背光配置 |
| `switch-to-dsi.sh` | 快速切换到5寸DSI屏 |
| `switch-to-hdmi.sh` | 快速切换到HDMI |
| `set-backlight.sh` | 设置背光亮度 |

## 快速安装

```bash
cd dsi_5in
sudo ./install.sh
sudo reboot
```

## 手动安装步骤

### 1. 复制设备树 overlay

```bash
sudo cp dsi-dfrobot-v1.dtbo /boot/overlays/
```

### 2. 配置启动 overlay

编辑 `/boot/config.txt`：
```
dtoverlay=dsi-dfrobot-v1
```

### 3. 配置背光自动开启

编辑 `/etc/rc.local`：
```bash
#!/bin/bash -e
echo 200 > /sys/class/backlight/panel_backlight/brightness
exit 0
```

### 4. 配置 X11 显示比例

复制配置文件：
```bash
cp xprofile ~/.xprofile
chmod +x ~/.xprofile
```

### 5. 重启系统

```bash
sudo reboot
```

## 显示切换命令

### 快速切换脚本

```bash
# 切换到5寸DSI屏
sudo ./switch-to-dsi.sh

# 切换到HDMI
sudo ./switch-to-hdmi.sh

# 设置背光亮度（0-255）
sudo ./set-backlight.sh 200
```

### 手动命令

```bash
# 切换到5寸DSI屏（推荐）
xrandr --output HDMI-1 --off
xrandr --output DSI-1 --mode 800x480 --scale 1.067x1.0 --primary

# 切换到HDMI
xrandr --output DSI-1 --off
xrandr --output HDMI-1 --auto

# 调整背光亮度 (0-255)
echo 200 > /sys/class/backlight/panel_backlight/brightness
```

## 常见问题

### 1. 屏幕白屏/无显示
- 检查背光是否开启：`cat /sys/class/backlight/panel_backlight/brightness`
- 确认 overlay 已正确加载：`ls /proc/device-tree/soc/disp_apb/mipi_dsi0@3e060000/`

### 2. 显示比例异常（横向压缩）
- 使用缩放修正：`xrandr --output DSI-1 --scale 1.067x1.0`

### 3. 触控不工作
- 检查驱动是否加载：`lsmod | grep ft5406`
- 检查 I2C 设备：`i2cdetect -y 3`

### 4. 无法与HDMI同时显示
- **RDK X5 硬件限制**：只能同时驱动一个显示输出（DSI 或 HDMI）
- 使用上述切换命令进行切换

### 5. 重启后黑屏/暗屏，但有背光变化（红绿蓝白）
- **现象**：开机有背光变化，但无法显示桌面
- **原因**：内核版本过旧（12月8日前）或 X11 配置错误
- **解决**：
  1. 升级系统：`sudo apt update && sudo apt upgrade -y`
  2. 重启：`sudo reboot`
  3. 如仍有问题，检查 Xorg 日志：`cat /var/log/Xorg.0.log | grep -iE "(EE|error)"`
  4. 删除可能冲突的 X11 配置：`sudo rm /etc/X11/xorg.conf.d/2-dr-accel.conf`

### 6. 登录时提示 ".xprofile: 权限不够"
- **原因**：普通用户无法直接写入背光设备
- **解决**：已在新版 xprofile 中使用 `sudo` 执行背光设置
- **手动修复**：编辑 `~/.xprofile`，将背光设置改为：
  ```bash
  sudo sh -c "echo 200 > /sys/class/backlight/panel_backlight/brightness" 2>/dev/null || true
  ```

### 7. 提示 "output HDMI-1 not found"
- **原因**：某些固件版本 HDMI 设备名称不同
- **解决**：新版 xprofile 已添加 `2>/dev/null || true` 忽略此错误

## 技术细节

### 驱动选择
- 使用 `wh-cm480` 驱动替代 `jc-050hd134`
- 原因：`jc-050hd134` 默认分辨率 720×1280（竖屏），与 DFR0550-V1 不匹配

### 显示比例修正
- 原始分辨率：800×480
- 像素比例修正：1.067:1（横向拉伸 6.7%）
- 修正后有效分辨率：854×480

### 背光控制
- 背光设备：`/sys/class/backlight/panel_backlight/`
- 亮度范围：0-255
- 默认设置：200

## 参考信息

- DFRobot Wiki: https://wiki.dfrobot.com.cn/_SKU_DFR0550-V2_5_inch_DSI_Touchsrceen_with_Optical_Bonding_for_Raspberry_Pi
- RDK X5 文档: https://developer.d-robotics.cc/

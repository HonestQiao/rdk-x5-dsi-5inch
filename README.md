# RDK X5 DSI 5寸屏适配指南

适用于 DFRobot DFR0550-V1 5寸 DSI 触摸屏（800×480分辨率）

## 硬件信息

- **屏幕型号**: DFRobot DFR0550-V1
- **分辨率**: 800×480（原生，无缩放）
- **接口**: MIPI DSI
- **触控**: 5点电容触控 (ft5406)
- **背光控制**: 支持 (panel_backlight)

## 快速安装（推荐）

```bash
cd dsi_5in
sudo ./install.sh
sudo reboot
```

重启后，5寸屏应该自动显示桌面。

## 文件说明

| 文件 | 说明 |
|------|------|
| `dsi-dfrobot-v1.dtbo` | 设备树 overlay（已编译，直接使用） |
| `install.sh` | 一键安装脚本 |
| `dsi-fix.sh` | LightDM显示设置脚本（开启背光+初始化DSI） |
| `dsi-session-fix.sh` | LightDM会话设置脚本（登录后配置） |
| `README.md` | 本文档 |

## 手动安装步骤

如果一键安装失败，可按以下步骤手动安装：

### 1. 复制设备树 overlay

```bash
sudo cp dsi-dfrobot-v1.dtbo /boot/overlays/
```

### 2. 配置启动 overlay

编辑 `/boot/config.txt`，添加：
```
dtoverlay=dsi-dfrobot-v1
```

### 3. 安装 LightDM 脚本

```bash
sudo cp dsi-fix.sh /usr/local/bin/
sudo cp dsi-session-fix.sh /usr/local/bin/
sudo chmod +x /usr/local/bin/dsi-fix.sh /usr/local/bin/dsi-session-fix.sh
```

创建 LightDM 配置文件 `/etc/lightdm/lightdm.conf.d/99-dsi-fix.conf`：
```
[Seat:*]
display-setup-script=/usr/local/bin/dsi-fix.sh
session-setup-script=/usr/local/bin/dsi-session-fix.sh
```

### 4. 配置用户 sudo 权限（免密码执行背光命令）

创建文件 `/etc/sudoers.d/99-dsi-backlight`：
```
sunrise ALL=(ALL) NOPASSWD: /bin/tee /sys/class/backlight/panel_backlight/brightness
```

### 5. 删除冲突配置

```bash
rm -f ~/.xprofile
```

### 6. 重启系统

```bash
sudo reboot
```

## 显示切换命令

### 手动命令

```bash
# 切换到5寸DSI屏
xrandr --output HDMI-1 --off
xrandr --output DSI-1 --auto
xrandr --output DSI-1 --mode 800x480 --primary

# 切换到HDMI
xrandr --output DSI-1 --off
xrandr --output HDMI-1 --auto

# 调整背光亮度 (0-255)
echo 200 | sudo tee /sys/class/backlight/panel_backlight/brightness
```

## 常见问题

### 1. 屏幕白屏/无显示/暗色
- 检查背光：`cat /sys/class/backlight/panel_backlight/brightness`
- 检查 overlay 加载：`cat /proc/device-tree/soc/disp_apb/mipi_dsi0@3e060000/dsi_panel0@0/compatible`
- 检查脚本执行：`systemctl status lightdm` 查看日志

### 2. 触控不工作
- 检查驱动：`lsmod | grep ft5406`
- 检查I2C设备：`i2cdetect -y 3 | grep 38`
- 检查输入设备：`xinput list | grep fts_ts`

### 3. 无法与HDMI同时显示
- **RDK X5 硬件限制**：只能同时驱动一个显示输出（DSI 或 HDMI）
- 使用切换脚本进行切换

### 4. 开机后屏幕闪烁多次（白红绿蓝）后暗色
这是正常的初始化过程。如果最终暗色无桌面：
- 检查 `~/.xprofile` 是否存在（应该删除）
- 检查 LightDM 日志：`/var/log/lightdm/lightdm.log`

## 技术细节

### 驱动选择
- 使用 `wh-cm480` 驱动替代默认的 `jc-050hd134`
- 原因：`jc-050hd134` 默认分辨率 720×1280（竖屏），与 DFR0550-V1 不匹配
- `wh-cm480` 支持 800×480 原生分辨率

### 为什么使用 LightDM 脚本而不是 ~/.xprofile
- `~/.xprofile` 以普通用户权限运行，无法设置背光（需要root）
- 权限错误会导致整个会话启动失败（xfce4无法启动）
- LightDM 的 `display-setup-script` 和 `session-setup-script` 在正确的时间点执行

### 启动流程
1. 系统启动 → 加载 `dsi-dfrobot-v1.dtbo` → 加载 `wh-cm480` 驱动
2. LightDM 启动 X11
3. `display-setup-script` (dsi-fix.sh) 执行：开启背光 + 初始化DSI
4. 用户自动登录
5. `session-setup-script` (dsi-session-fix.sh) 执行：确保显示配置正确
6. xfce4 桌面启动

## 目录结构

```
dsi_5in/
├── dsi-dfrobot-v1.dtbo      # 设备树overlay（直接使用）
├── install.sh               # 一键安装脚本
├── dsi-fix.sh               # LightDM显示设置脚本
├── dsi-session-fix.sh       # LightDM会话设置脚本
└── README.md                # 本文档
```

## 参考信息

- DFRobot Wiki: https://wiki.dfrobot.com.cn/_SKU_DFR0550-V2_5_inch_DSI_Touchsrceen_with_Optical_Bonding_for_Raspberry_Pi
- RDK X5 文档: https://developer.d-robotics.cc/

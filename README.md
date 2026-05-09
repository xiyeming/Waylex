<p align="center">
  <img src="flutter/assets/icons/tray_icon.png" width="80" alt="Waylex">
</p>

<h1 align="center">Waylex</h1>

<p align="center">
  AI 驱动的跨平台桌面翻译工具 | 截图即译 · 多厂商对比 · 全局快捷键
</p>

<p align="center">
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-MIT-blue.svg" alt="License"></a>
  <img src="https://img.shields.io/badge/platform-Linux%20%7C%20Windows%20%7C%20macOS-orange" alt="Platform">
  <img src="https://img.shields.io/badge/language-Rust%20%2B%20Flutter-purple" alt="Language">
</p>

> 因为 Linux Wayland 没有好用的翻译工具，所以我自己开发了一个。<br>
> 现已通过平台抽象层重构，支持 Linux、Windows、macOS 三大平台。<br>
> Linux 端在 **CachyOS + Hyprland** 环境验证最充分，其他平台/桌面环境持续完善中。<br>
> 有 Bug 欢迎提 Issue，但不一定会及时修复 😄

---

## 功能特性

- **多厂商翻译** — OpenAI、DeepL、Google、Qwen、DeepSeek、Kimi、GLM、Anthropic、Azure、Custom，10 家厂商即配即用
- **厂商对比** — 同时对比多家翻译结果，展示响应时间与 Token 消耗
- **截图翻译** — 快捷键框选区域 → OCR 识别 → 自动翻译，一键完成
- **提示词模板** — 自定义多套系统提示词，翻译时一键切换
- **全局快捷键** — 跨平台全局热键，Linux 端支持 Hyprland IPC / KDE KGlobalAccel / evdev 三层自适应，快捷键实时录制修改
- **系统托盘** — 最小化到托盘，左键唤醒，右键快捷菜单
- **浮动窗口** — 无边框置顶，拖拽自由

## 截图

<p align="center">
  <i>翻译主界面 / 厂商设置 / 快捷键录制</i>
</p>

## 安装

从 [Releases](https://github.com/xiyeming/Waylex/releases) 下载对应系统的安装包。

| 文件 | 系统/架构 | 格式 |
|------|----------|------|
| `Waylex-linux-x86_64.AppImage` | Linux x86_64 | AppImage（推荐） |
| `Waylex-linux-aarch64.AppImage` | Linux ARM64 | AppImage |
| `waylex-linux-x64.tar.gz` | Linux x86_64 | 便携压缩包 |
| `waylex-linux-aarch64.tar.gz` | Linux ARM64 | 便携压缩包 |
| `Waylex.flatpak` | Linux x86_64 | Flatpak |
| `waylex-macos-universal.zip` | macOS (Intel/Apple Silicon) | 应用包 |
| `waylex-windows-x64.zip` | Windows x64 | 便携压缩包 |

---

### Linux

#### AppImage（推荐，无需 root）

```bash
# x86_64
chmod +x Waylex-linux-x86_64.AppImage
./Waylex-linux-x86_64.AppImage

# ARM64 (aarch64，如树莓派、Asahi Linux)
chmod +x Waylex-linux-aarch64.AppImage
./Waylex-linux-aarch64.AppImage
```

> 首次运行若提示 FUSE 缺失，可使用 `--appimage-extract` 解压后运行 `squashfs-root/AppRun`。

#### Flatpak

```bash
flatpak install Waylex.flatpak
flatpak run com.xym.ft.Waylex
```

#### 便携压缩包

```bash
# x86_64
tar xzf waylex-linux-x64.tar.gz
cd bundle && ./Waylex

# ARM64
tar xzf waylex-linux-aarch64.tar.gz
cd bundle && ./Waylex
```

#### 系统依赖

Linux 端以下功能依赖外部命令，目标机器需预装：

| 包 | 用途 | 安装命令 (Arch) |
|----|------|----------------|
| `wl-clipboard` | Wayland 剪贴板读写 | `sudo pacman -S wl-clipboard` |
| `grim` + `slurp` | 截图 + 交互式选区 | `sudo pacman -S grim slurp` |
| `tesseract` + `tesseract-data-eng` + `tesseract-data-chi_sim` | OCR 引擎 + 中英文语言包 | `sudo pacman -S tesseract tesseract-data-eng tesseract-data-chi_sim` |

```bash
# Ubuntu/Debian
sudo apt install wl-clipboard grim slurp tesseract-ocr tesseract-ocr-eng tesseract-ocr-chi-sim

# Fedora
sudo dnf install wl-clipboard grim slurp tesseract tesseract-langpack-eng tesseract-langpack-chi_sim
```

#### 全局快捷键权限

- **Hyprland / Sway**：evdev 热键需要 `input` 组权限。AppImage/便携包需要此权限，Flatpak 使用 Hyprland IPC  fallback 可不依赖。
  ```bash
  sudo usermod -aG input $USER
  # 重新登录生效
  ```
- **KDE Plasma**：通过 KGlobalAccel D-Bus 注册，无需额外权限。

#### Hyprland 窗口规则

将以下内容添加到 `~/.config/hypr/hyprland.conf`：

```hypr
windowrule {
    match:class = ^(com.xym.ft)$
    float = true
    size = 400 600
    center = true
    pin = true
}
```

> 项目内 `hyprland/flutter-translate.conf` 为独立配置文件，可用 `source = ~/CodeSpaces/RustProjects/Waylex/hyprland/flutter-translate.conf` 引入。

---

### Windows

下载 `waylex-windows-x64.zip`，解压后运行 `Waylex.exe`。

#### 系统依赖

| 依赖 | 说明 |
|------|------|
| Tesseract OCR | 需添加到 PATH，或放在应用同目录 |
| Visual C++ Redistributable | 若启动失败，安装最新 VC++ 运行时 |

首次运行需授予**屏幕录制**权限（截图 OCR 功能需要）。

---

### macOS

下载 `waylex-macos-universal.zip`，解压后将 `Waylex.app` 拖入 **应用程序** 文件夹。

#### 系统依赖

```bash
brew install tesseract tesseract-lang
```

首次运行需授予：
- **辅助功能**权限（全局热键）
- **屏幕录制**权限（截图 OCR）

---

### 从源码构建

| 依赖 | 版本 |
|------|------|
| Rust | 1.95+ |
| Flutter | 3.41+ |
| CMake | — |

```bash
# 安装 Rust
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

# Linux: 安装 Flutter (Arch)
sudo pacman -S flutter

# 构建
git clone https://github.com/xiyeming/flutter-translate.git
cd flutter-translate

# Linux
./scripts/build.sh

# Windows (PowerShell)
cd native && cargo build --release --target x86_64-pc-windows-msvc
cd ../flutter && flutter build windows --release

# macOS
cd native && cargo build --release --target aarch64-apple-darwin
cd ../flutter && flutter build macos --release
```

各平台详细构建步骤见：
- [docs/windows-build.md](docs/windows-build.md)
- [docs/macos-build.md](docs/macos-build.md)
- [docs/跨平台重构设计文档.md](docs/跨平台重构设计文档.md)

## 使用

### 配置 API Key

应用内：**设置 → 厂商 → 点击厂商卡片 → 填写 API Key → 保存**

或设置环境变量：

```bash
export OPENAI_API_KEY="sk-..."
export DEEPSEEK_API_KEY="sk-..."
export DASHSCOPE_API_KEY="sk-..."   # Qwen
export ANTHROPIC_API_KEY="sk-..."
export DEEPL_API_KEY="your-key"
```

### 快捷键

| 快捷键 | 功能 |
|--------|------|
| `Super+Alt+F` | 翻译选中文本（先 Ctrl+C 复制，再按快捷键） |
| `Ctrl+Shift+S` | 截图 OCR → 自动翻译 |
| `Ctrl+Shift+F` | 显示/隐藏窗口 |
| `Enter` | 翻译输入框内容（Shift+Enter 换行） |

> 快捷键可在 **设置 → 快捷键** 中实时录制修改

### 提示词模板

1. 翻译主界面 → 点击提示词选择器旁的 **+**
2. 新增模板：输入名称和提示词内容
3. 激活后自动覆盖所有厂商的 system prompt
4. 下拉切换或恢复 "使用厂商默认提示词"

## 技术栈

| 层 | 技术 |
|----|------|
| UI | Flutter 3.41 + Riverpod + go_router |
| FFI | flutter_rust_bridge 2.12 |
| 后端 | Rust (Tokio, reqwest, sqlx, chrono) |
| 存储 | SQLite + keyring (回退 SQLite) |
| 平台抽象 | `PlatformBackend` trait + 条件编译 (`#[cfg]`) |
| 热键 | Linux: evdev / Hyprland IPC / KDE KGlobalAccel；Win/macOS: global-hotkey |
| OCR | tesseract CLI + image crate 预处理 |
| 截图 | Linux: grim + slurp；Windows: xcap；macOS: screencapture |
| 剪贴板 | Linux: wl-clipboard-rs；Win/macOS: arboard |
| 托盘 | Linux: zbus SNI；Win/macOS: tray-icon |
| 打包 | Linux: AppImage |

## 架构

```
Flutter ——FFI——→ flutter_rust_bridge ——→ translate (10 厂商)
                  ├── config (SQLite + keyring)
                  └── platform (PlatformBackend trait)
                        ├── linux/   (evdev / Hyprland IPC / KDE / grim+slurp / wl-clipboard / zbus SNI)
                        ├── windows/ (global-hotkey / arboard / xcap / tray-icon)
                        └── macos/   (global-hotkey / arboard / screencapture / tray-icon)
```

## 项目结构

```
flutter-translate/
├── native/src/                  # Rust 后端
│   ├── ffi/bridge.rs            # FFI 接口：翻译/配置/平台能力调用
│   ├── ffi/types.rs             # FFI 类型定义
│   ├── ffi/error.rs             # 错误类型
│   ├── platform/                # 【平台抽象层】
│   │   ├── mod.rs               # PlatformBackend trait + 工厂 + 单例
│   │   ├── common/              # 跨平台共用（OCR tesseract 引擎）
│   │   ├── linux/               # Linux 实现
│   │   │   ├── mod.rs           # LinuxBackend
│   │   │   ├── hotkey/          # evdev + Hyprland IPC + KDE
│   │   │   ├── clipboard.rs     # wl-clipboard-rs
│   │   │   ├── screenshot.rs    # grim + slurp
│   │   │   └── tray/            # zbus SNI
│   │   ├── windows/             # Windows 实现
│   │   │   └── mod.rs           # WindowsBackend (global-hotkey / arboard / xcap / tray-icon)
│   │   └── macos/               # macOS 实现
│   │       └── mod.rs           # MacOsBackend (global-hotkey / arboard / screencapture / tray-icon)
│   ├── config/                  # SQLite 配置 + keyring API Key
│   ├── translate/               # 10 厂商翻译引擎
│   └── tests/                   # 单元测试 + 集成测试
├── flutter/lib/                 # Flutter 前端
│   ├── app/                     # 路由 + 主题
│   ├── data/                    # 模型 + 数据源 + Repository
│   └── presentation/            # 页面 + Services
├── scripts/                     # build.sh / release.sh / gen_bridge.sh
├── hyprland/                    # Hyprland 窗口规则
└── docs/                        # 开发文档
```

## 贡献

欢迎提交 Issue 和 Pull Request。

```bash
# 开发流程
cd native && cargo check && cargo test      # Rust
cd flutter && flutter analyze               # Flutter
./scripts/build.sh                           # Linux 完整构建
```

跨平台重构相关文档：
- [docs/跨平台重构设计文档.md](docs/跨平台重构设计文档.md) — 架构设计、trait 定义、阶段规划
- [docs/windows-build.md](docs/windows-build.md) — Windows 构建环境配置
- [docs/macos-build.md](docs/macos-build.md) — macOS 构建环境配置

## License

[MIT](LICENSE) © 2026 [xiyeming](mailto:xiyeming@163.com)

# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 项目概述

Waylex 是一款 AI 驱动的 Linux Wayland 桌面翻译工具，采用 Flutter 前端 + Rust 后端的混合架构，通过 flutter_rust_bridge 进行 FFI 通信。

- **平台限制**：仅支持 Linux Wayland，已在 CachyOS + Hyprland 环境验证
- **前端**：Flutter 3.41+ / Riverpod / go_router / window_manager / tray_manager
- **后端**：Rust 1.95+ (edition 2024) / flutter_rust_bridge 2.12 / tokio / sqlx

## 常用命令

### 完整构建

```bash
./scripts/build.sh          # Rust release + FFI 生成 + Flutter linux release
./scripts/gen_bridge.sh     # 仅重新生成 FFI 绑定代码
./scripts/release.sh        # 构建并打包为 AppImage
```

### Rust 后端开发 (`native/`)

```bash
cd native
cargo check                          # 快速检查
cargo test                           # 运行所有测试
cargo test --test integration_test   # 运行集成测试
cargo test config_test               # 运行单个测试文件
cargo clippy                         # Lint
```

### Flutter 前端开发 (`flutter/`)

```bash
cd flutter
flutter analyze                      # 静态分析
flutter build linux --debug          # Debug 构建
flutter test                         # 运行测试
flutter pub run build_runner build   # 生成 freezed / json_serializable 代码
```

### 调试运行

构建完成后：

```bash
cd flutter/build/linux/x64/release/bundle && ./run.sh
```

## 项目结构

```
flutter-translate/
├── flutter/                  # Flutter 前端
│   ├── lib/
│   │   ├── app/              # 路由 (go_router) + 主题
│   │   ├── core/             # 常量、枚举、错误类型、工具
│   │   ├── data/             # 模型 (freezed) + Repository + FFI Datasource
│   │   ├── domain/           # Entity + UseCase
│   │   ├── presentation/     # 页面 + Widgets + Services + Riverpod Providers
│   │   └── src/rust/         # flutter_rust_bridge 生成代码 (自动生成，勿手动修改)
│   └── assets/icons/         # 托盘图标
├── native/                   # Rust 后端
│   └── src/
│       ├── ffi/              # FFI 桥接：bridge.rs (所有导出函数) / types.rs / error.rs
│       ├── translate/        # 翻译引擎：10 家厂商 Provider + Router + Engine
│       ├── config/           # SQLite 配置 (sqlx) + keyring API Key 存储 + 桌面环境检测
│       ├── hotkey/           # evdev / Hyprland IPC / KDE 三层热键实现
│       ├── ocr/              # grim+slurp 截图 + tesseract OCR + image 预处理
│       ├── clipboard/        # wl-clipboard CLI 调用
│       ├── tray/             # zbus SNI 系统托盘
│       └── tests/            # 单元测试
├── scripts/                  # build.sh / gen_bridge.sh / release.sh / package_appimage.sh
├── hyprland/                 # Hyprland 窗口规则配置
└── docs/                     # 开发文档 (需求、架构、任务拆解)
```

## 架构要点

### FFI 通信边界

所有 Dart/Rust 通信通过 `native/src/ffi/bridge.rs` 中标记 `#[frb]` 的函数，在 `flutter/lib/src/rust/` 生成对应的 Dart 代码。

- `native/src/ffi/bridge.rs` 是 FFI 的唯一入口。新增跨语言功能时，先在此添加 `#[frb]` 函数，然后运行 `./scripts/gen_bridge.sh`。
- Flutter 侧不直接调用 bridge，而是通过 `lib/data/datasources/ffi_datasource.dart` 包装，进行类型映射（bridge 类型 → app 模型）和错误转换。

### 配置管理三层回退

`native/src/ffi/bridge.rs` 中 `resolve_config()` 实现配置解析的优先级：

1. **已保存的 SQLite 配置**（用户设置）
2. **环境变量**（`OPENAI_API_KEY` 等，用于快速配置）
3. **硬编码默认值**（URL + model，如 `https://api.openai.com/v1` / `gpt-4o-mini`）

API Key 的存储策略（`native/src/config/secret.rs`）：
- **主存储**：SQLite `provider_keys` 表（所有平台可靠）
- **兼容回退**：keyring（libsecret），失败静默忽略

### 翻译引擎架构

`native/src/translate/mod.rs` 定义了 `TranslateProvider` trait 和 `ProviderRegistry`。但实际翻译调用在 `ffi/bridge.rs` 中直接通过 `match provider_id` 分发到各个 `translate_*` 函数（非 trait 动态分发）。10 家厂商中 openai/deepseek/qwen/kimi/glm/custom 共用 `translate_openai_compat()`，其余各家独立实现。

翻译调用链路：UI 输入 → `TranslationService.translate()` → `ffi_datasource.dart` → `bridge.rs translate_text()` → `match provider_id` → 具体厂商实现 → 返回 `TranslationResult`。

### 热键三层自适应

`native/src/hotkey/mod.rs` 的 `HotkeyService::register_all()` 按桌面环境选择实现：

- **Hyprland**：优先 evdev（需 `input` 组权限）→ 失败回退 Hyprland IPC socket
- **KDE**：优先 KGlobalAccel D-Bus → 失败回退 evdev
- **其他/Unknown**：evdev

Flutter 侧通过 `HotkeyService` 每 200ms 轮询 `pollHotkeyEvent()` 获取热键事件（`presentation/services/hotkey_service.dart`）。

默认快捷键配置（可在设置中录制修改）：

| 快捷键 | 功能 |
|--------|------|
| `Super+Alt+F` | 翻译剪贴板内容 |
| `Ctrl+Shift+S` | 截图 OCR → 自动翻译 |
| `Ctrl+Shift+F` | 显示/隐藏浮动窗口 |

### OCR 截图管道

`native/src/ocr/mod.rs` 的 `OcrService`：

1. `screenshot()` → 调用 `grim` + `slurp` 获取选区截图
2. `recognize()` → spawn_blocking 中执行：image crate 预处理（灰度 → 对比度 → 2x 放大）→ 写临时文件 → `tesseract` CLI 识别

### 核心数据库表结构

SQLite 数据库由 `native/src/config/storage.rs` 初始化，主要表：

| 表名 | 关键字段 | 说明 |
|------|---------|------|
| `providers` | id, name, api_url, model, auth_type, is_active, sort_order, system_prompt | 厂商配置（api_key 分离存储） |
| `provider_keys` | provider_id, encrypted_key | API Key 主存储（当 keyring 不可用时） |
| `prompt_templates` | id, name, content, is_active | 提示词模板 |
| `shortcut_bindings` | id, action, key_combination, enabled | 快捷键绑定 |
| `active_sessions` | id=1, last_provider_id, last_compare_providers | 上一次使用的会话状态 |
| `user_config` | id='default', theme, default_target_lang, auto_detect | 用户全局偏好 |

### Provider 状态管理（SQLite 为单一数据源）

厂商配置和激活状态由 Rust 侧 `ConfigManager`（`native/src/config/mod.rs`）统一管理，以 SQLite `providers` 表为唯一数据源。

- **`is_active` 字段**：表示用户是否启用该厂商（需同时满足 `is_active = true` 且 `api_key` 不为空）
- **获取 Provider 列表**：Flutter 侧通过 `ffi_datasource.getProviders()` → `ConfigManager::get_all_providers()` 读取，Rust 侧自动关联 `secret::get_api_key()` 填充 `api_key` 字段
- **保存/更新**：`ffi_datasource.saveProvider()` → `ConfigManager::save_provider()`，API Key 分离存储到 `secret` 模块（SQLite `provider_keys` 表或 keyring），其余字段存入 `providers` 表
- **激活状态切换**：直接修改 `providers` 表的 `is_active` 字段，Flutter 侧通过重新获取列表刷新状态

Flutter 侧业务逻辑主要在 `presentation/services/` 下的 Service 类（`HotkeyService`、`TranslationService` 等），通过 `ffi_datasource.dart` 调用 Rust，Riverpod Provider 多为状态持有者而非业务逻辑主体。

### 提示词模板系统

`native/src/config/mod.rs` 提供完整的提示词模板 CRUD：`get_all_prompt_templates()` / `save_prompt_template()` / `delete_prompt_template()` / `get_active_prompt()`。

- 数据库表：`prompt_templates`（id, name, content, is_active, created_at）
- 激活机制：设置模板为 `is_active = 1` 时，Rust 侧自动将该模板内容覆盖所有厂商翻译请求的 system prompt；未激活时使用厂商默认提示词
- 同时只能有一个模板处于激活状态（`save_prompt_template` 会自动重置其他模板的 `is_active`）
- FFI 接口：`getPromptTemplates()` / `savePromptTemplate()` / `deletePromptTemplate()` / `getActivePrompt()`

### 路由

`lib/app/router/app_router.dart` 使用 go_router，5 个路由：
- `/` - 浮动窗口 (FloatingPage)
- `/main` - 主页面 (MainPage)
- `/compare` - 多厂商对比 (ComparePage)
- `/settings` - 设置 (SettingsPage)
- `/settings/provider?id=...` - 厂商编辑 (ProviderEditPage)

## 开发注意事项

### 新增 FFI 接口的流程

1. 在 `native/src/ffi/bridge.rs` 添加 `#[frb]` 函数
2. 如需新类型，在 `native/src/ffi/types.rs` 添加并标记 `#[frb]`
3. 运行 `./scripts/gen_bridge.sh` 生成 Dart 代码
4. 在 `flutter/lib/data/datasources/ffi_datasource.dart` 添加包装方法和类型映射

### 代码生成文件

以下文件由工具自动生成，**不要手动修改**：

- `flutter/lib/src/rust/frb_generated*.dart`
- `flutter/lib/data/models/*.freezed.dart`
- `flutter/lib/data/models/*.g.dart`

修改对应源文件后运行：

```bash
cd flutter && flutter pub run build_runner build   # freezed/json_serializable
cd flutter && flutter_rust_bridge_codegen generate  # FFI 绑定
```

### 测试

- Rust 测试在 `native/src/tests/`，使用 `mockito` 进行 HTTP mock
- Flutter 测试框架已配置但用例较少
- 集成测试需要实际桌面环境或外部命令（tesseract、wl-clipboard），部分测试标记 `#[ignore]`

### 关键环境变量

运行时可配置：

```bash
export OPENAI_API_KEY="sk-..."
export DEEPSEEK_API_KEY="sk-..."
export DASHSCOPE_API_KEY="sk-..."      # Qwen
export ANTHROPIC_API_KEY="sk-..."
export DEEPL_API_KEY="your-key"
```

### 系统依赖

目标机器需预装：`wl-clipboard` `grim` `slurp` `tesseract` `tesseract-data-eng` `tesseract-data-chi_sim`

evdev 热键需要 `input` 组权限：`sudo usermod -aG input $USER`

## 相关文档

- `docs/需求文档.md` - 功能需求
- `docs/rust-backend-dev.md` - Rust 后端详细设计（含架构图、FFI 设计、SQLite Schema）
- `docs/flutter-frontend-dev.md` - Flutter 前端开发文档
- `docs/ffi-api-design.md` - FFI API 设计
- `docs/开发任务拆解.md` - 开发任务拆解

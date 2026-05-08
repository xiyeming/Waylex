#!/bin/bash

set -e

# ============================================================================
# Waylex 多平台构建脚本
# ============================================================================
# 用法:
#   ./scripts/build.sh [TARGET_OS] [TARGET_ARCH]
#
# 支持的平台组合:
#   linux   x86_64  (默认)
#   linux   aarch64
#   windows x86_64
#   macos   x86_64
#   macos   aarch64
# ============================================================================

TARGET_OS="${1:-linux}"
TARGET_ARCH="${2:-x86_64}"

echo "=== Waylex Build Script ==="
echo "Target: $TARGET_OS / $TARGET_ARCH"

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
FLUTTER_DIR="$PROJECT_DIR/flutter"
NATIVE_DIR="$PROJECT_DIR/native"

# 映射到 Rust target triple
case "${TARGET_OS}_${TARGET_ARCH}" in
    linux_x86_64)
        RUST_TARGET="x86_64-unknown-linux-gnu"
        LIB_NAME="libflutter_translate_native.so"
        FLUTTER_BUILD_ARCH="x64"
        ;;
    linux_aarch64)
        RUST_TARGET="aarch64-unknown-linux-gnu"
        LIB_NAME="libflutter_translate_native.so"
        FLUTTER_BUILD_ARCH="arm64"
        ;;
    windows_x86_64)
        RUST_TARGET="x86_64-pc-windows-msvc"
        LIB_NAME="flutter_translate_native.dll"
        FLUTTER_BUILD_ARCH=""
        ;;
    macos_x86_64)
        RUST_TARGET="x86_64-apple-darwin"
        LIB_NAME="libflutter_translate_native.dylib"
        FLUTTER_BUILD_ARCH=""
        ;;
    macos_aarch64)
        RUST_TARGET="aarch64-apple-darwin"
        LIB_NAME="libflutter_translate_native.dylib"
        FLUTTER_BUILD_ARCH=""
        ;;
    *)
        echo "Error: Unsupported platform combination: $TARGET_OS / $TARGET_ARCH"
        echo "Supported combinations:"
        echo "  linux x86_64"
        echo "  linux aarch64"
        echo "  windows x86_64"
        echo "  macos x86_64"
        echo "  macos aarch64"
        exit 1
        ;;
esac

# 检查 Rust target 是否已安装
if ! rustup target list --installed | grep -q "^${RUST_TARGET}$"; then
    echo "Warning: Rust target ${RUST_TARGET} is not installed."
    echo "Install it with: rustup target add ${RUST_TARGET}"

    # 对于交叉编译目标，给出额外提示
    case "$RUST_TARGET" in
        aarch64-unknown-linux-gnu)
            echo "Note: You may also need a cross-compilation toolchain (e.g., gcc-aarch64-linux-gnu)"
            ;;
    esac

    exit 1
fi

# Build Rust library
echo "Building Rust library for ${RUST_TARGET}..."
cd "$NATIVE_DIR"
cargo build --release --target "$RUST_TARGET"

RUST_TARGET_DIR="$NATIVE_DIR/target/${RUST_TARGET}/release"
echo "Rust library built: ${RUST_TARGET_DIR}/${LIB_NAME}"

# Generate FFI bindings (platform-agnostic)
echo "Generating FFI bindings..."
cd "$FLUTTER_DIR"
flutter_rust_bridge_codegen generate

# Flutter 构建仅在 Linux 上执行（当前 Waylex 仅支持 Linux Flutter 桌面）
if [ "$TARGET_OS" = "linux" ]; then
    echo "Copying native library to Flutter bundle..."
    BUNDLE_LIB_DIR="$FLUTTER_DIR/build/linux/${FLUTTER_BUILD_ARCH}/release/bundle/lib"
    mkdir -p "$BUNDLE_LIB_DIR"
    cp "${RUST_TARGET_DIR}/${LIB_NAME}" "$BUNDLE_LIB_DIR/"
    echo "Native library copied to $BUNDLE_LIB_DIR/"

    echo "Building Flutter app..."
    cd "$FLUTTER_DIR"
    flutter build linux --release

    # Re-copy native library (flutter build may recreate bundle)
    echo "Re-copying native library after Flutter build..."
    cp "${RUST_TARGET_DIR}/${LIB_NAME}" "$BUNDLE_LIB_DIR/"

    # Create wrapper script for proper library loading
    echo "Creating wrapper script..."
    cat > "$FLUTTER_DIR/build/linux/${FLUTTER_BUILD_ARCH}/release/bundle/run.sh" << 'WRAPPER'
#!/bin/bash
SELF="$(readlink -f "$0")"
BUNDLE_DIR="$(dirname "$SELF")"
export LD_LIBRARY_PATH="$BUNDLE_DIR/lib:$LD_LIBRARY_PATH"
exec "$BUNDLE_DIR/Waylex" "$@"
WRAPPER
    chmod +x "$FLUTTER_DIR/build/linux/${FLUTTER_BUILD_ARCH}/release/bundle/run.sh"

    echo "Build complete! Output: $FLUTTER_DIR/build/linux/${FLUTTER_BUILD_ARCH}/release/bundle/"
    echo "Run with: cd $FLUTTER_DIR/build/linux/${FLUTTER_BUILD_ARCH}/release/bundle && ./run.sh"
else
    echo ""
    echo "Rust library build complete for ${TARGET_OS} ${TARGET_ARCH}."
    echo "Output: ${RUST_TARGET_DIR}/${LIB_NAME}"
    echo ""
    echo "Note: Flutter desktop build is currently only supported on Linux."
    echo "To use this library, integrate it into your platform-specific Flutter build pipeline."
fi

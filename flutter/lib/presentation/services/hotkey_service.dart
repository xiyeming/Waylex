import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../data/datasources/ffi_datasource.dart';
import '../../data/models/shortcut_binding.dart';

class HotkeyService {
  static final HotkeyService _instance = HotkeyService._internal();
  factory HotkeyService() => _instance;
  HotkeyService._internal();

  final _hotkeyController = StreamController<String>.broadcast();
  Stream<String> get hotkeyStream => _hotkeyController.stream;

  bool _disposed = false;

  Timer? _pollTimer;
  Timer? _watchdogTimer;
  DateTime? _lastWatchdogTick;
  final _ffi = FfiDatasource();

  String _describeBindings(List<ShortcutBinding> bindings) {
    if (bindings.isEmpty) return 'none';
    return bindings
        .map(
          (b) =>
              '${b.action}=${b.keyCombination}${b.enabled ? '' : '(disabled)'}',
        )
        .join(', ');
  }

  Future<void> registerAll() async {
    try {
      debugPrint('[hotkey] ========== registerAll START ==========');
      final bindings = await _ffi.getShortcuts();
      debugPrint(
        '[hotkey] DB returned ${bindings.length} bindings: ${_describeBindings(bindings)}',
      );
      if (bindings.isEmpty) {
        final defaults = [
          ShortcutBinding(
            id: 'translate_selected',
            action: 'translate_selected',
            keyCombination: 'Super+Alt+F',
            enabled: true,
          ),
          ShortcutBinding(
            id: 'ocr_screenshot',
            action: 'ocr_screenshot',
            keyCombination: 'Ctrl+Shift+S',
            enabled: true,
          ),
          ShortcutBinding(
            id: 'toggle_window',
            action: 'toggle_window',
            keyCombination: 'Ctrl+Shift+F',
            enabled: true,
          ),
        ];
        for (final b in defaults) {
          await _ffi.updateShortcut(b);
        }
        debugPrint('[hotkey] saved ${defaults.length} default shortcuts');
        await _ffi.registerHotkeys(defaults);
        debugPrint('[hotkey] FFI registerHotkeys(defaults) returned OK');
      } else {
        debugPrint(
          '[hotkey] registering ${bindings.length} saved shortcuts via FFI',
        );
        await _ffi.registerHotkeys(bindings);
        debugPrint('[hotkey] FFI registerHotkeys(saved) returned OK');
      }

      debugPrint('[hotkey] ========== registerAll DONE, starting poll ==========');
      _startPolling();
    } catch (e) {
      debugPrint('[hotkey] registerAll FAILED: $e');
    }
  }

  Future<void> updateAndReregister(List<ShortcutBinding> bindings) async {
    try {
      debugPrint('[hotkey] ========== updateAndReregister START ==========');
      debugPrint('[hotkey] input: ${bindings.length} bindings');
      _stopPolling();
      debugPrint('[hotkey] poll/watchdog stopped');
      await _ffi.unregisterHotkeys();
      debugPrint('[hotkey] FFI unregisterHotkeys OK');
      for (final b in bindings) {
        await _ffi.updateShortcut(b);
      }
      final enabled = bindings.where((b) => b.enabled).toList();
      debugPrint(
        '[hotkey] saving ${bindings.length} bindings, registering ${enabled.length} enabled',
      );
      await _ffi.registerHotkeys(enabled);
      debugPrint('[hotkey] FFI registerHotkeys(enabled) OK');
      debugPrint('[hotkey] ========== updateAndReregister DONE ==========');
      _startPolling();
    } catch (e) {
      debugPrint('[hotkey] updateAndReregister FAILED: $e');
    }
  }

  void _startPolling() {
    if (_disposed) return;
    _pollTimer?.cancel();
    _watchdogTimer?.cancel();
    debugPrint('[hotkey] poll started (200ms)');
    _pollTimer = Timer.periodic(const Duration(milliseconds: 200), (_) async {
      if (_disposed) return;
      try {
        final event = await _ffi.pollHotkeyEvent();
        if (event != null && event.isNotEmpty) {
          debugPrint('[hotkey] polled event from Rust: "$event"');
          debugPrint('[hotkey] dispatching action=$event to stream');
          _hotkeyController.add(event);
        }
      } catch (e) {
        debugPrint('[hotkey] poll error: $e');
      }
    });
    _startWatchdog();
  }

  void _startWatchdog() {
    if (_disposed) return;
    _watchdogTimer?.cancel();
    _lastWatchdogTick = DateTime.now();
    debugPrint('[hotkey] watchdog started');
    _watchdogTimer = Timer.periodic(const Duration(minutes: 1), (_) async {
      if (_disposed) return;
      final now = DateTime.now();
      final last = _lastWatchdogTick;
      _lastWatchdogTick = now;
      if (last == null) return;

      final diff = now.difference(last);
      // 如果两次 watchdog 间隔超过 3 分钟，说明系统可能从睡眠/锁屏中恢复
      if (diff.inMinutes > 3) {
        debugPrint(
          '[hotkey] System resumed from sleep/lock (gap ${diff.inMinutes}m), re-registering hotkeys',
        );
        await _reRegister();
      }
    });
  }

  Future<void> _reRegister() async {
    try {
      debugPrint('[hotkey] _reRegister: re-reading bindings from Rust');
      final bindings = await _ffi.getShortcuts();
      final enabled = bindings.where((b) => b.enabled).toList();
      if (enabled.isEmpty) {
        debugPrint('[hotkey] _reRegister: no enabled bindings, skip');
        return;
      }
      await _ffi.unregisterHotkeys();
      debugPrint('[hotkey] _reRegister: unregister OK');
      await _ffi.registerHotkeys(enabled);
      debugPrint(
        '[hotkey] _reRegister: re-registered ${enabled.length} hotkeys after resume',
      );
    } catch (e) {
      debugPrint('[hotkey] _reRegister FAILED: $e');
    }
  }

  void _stopPolling() {
    debugPrint('[hotkey] stopping poll/watchdog timers');
    _pollTimer?.cancel();
    _pollTimer = null;
    _watchdogTimer?.cancel();
    _watchdogTimer = null;
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    debugPrint('[hotkey] ========== dispose START ==========');
    _stopPolling();
    debugPrint('[hotkey] poll stopped, closing stream');
    _hotkeyController.close();
    debugPrint('[hotkey] ========== dispose DONE ==========');
  }

  /// 模拟热键事件（用于托盘菜单等非键盘触发场景）
  void simulateEvent(String action) {
    if (_disposed) {
      debugPrint('[hotkey] simulateEvent SKIP (disposed): $action');
      return;
    }
    debugPrint('[hotkey] simulateEvent: $action');
    _hotkeyController.add(action);
  }
}

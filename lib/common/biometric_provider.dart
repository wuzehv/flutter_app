import 'package:flutter/material.dart';
import 'biometric_service.dart';
import 'config.dart';
import 'device_utils.dart';

class BiometricProvider extends ChangeNotifier {
  final BiometricService _biometricService = BiometricService();
  
  bool _isAuthenticated = false;
  bool _hasBiometric = false;
  bool _isDebugDevice = false; // 是否为调试设备
  bool _isLoading = true;
  bool _requireAuth = true; // 默认需要验证

  bool get isAuthenticated => _isAuthenticated;
  bool get hasBiometric => _hasBiometric;
  bool get isDebugDevice => _isDebugDevice;
  bool get isLoading => _isLoading;
  bool get requireAuth => _requireAuth;

  /// 初始化检查设备生物识别能力
  Future<void> init() async {
    print('🔵 BiometricProvider 开始初始化');
    try {
      // 首先检查是否为调试设备（模拟器等）
      _isDebugDevice = await DeviceUtils.isDebugDevice();
      print('📱 是否为调试设备：$_isDebugDevice');
      
      // 如果是调试设备，不需要验证
      if (_isDebugDevice) {
        _requireAuth = false;
        _hasBiometric = false;
        _isAuthenticated = true;
        _isLoading = false;
        notifyListeners();
        print('✅ 白名单设备，跳过指纹验证');
        return;
      }
      
      // 非白名单设备（真机）：一律需要指纹验证
      _hasBiometric = true;
      _isLoading = false;
      notifyListeners();
      
      print('🔒 非白名单设备，需要指纹验证 (requireAuth=$_requireAuth, isAuthenticated=$_isAuthenticated)');
    } catch (e) {
      _hasBiometric = false;
      _isDebugDevice = false;
      _isLoading = false;
      notifyListeners();
      print('❌ 初始化生物识别失败：$e');
    }
  }

  /// 执行生物识别验证
  Future<bool> authenticate({String? reason}) async {
    print('🔐 开始调用系统生物识别验证...');
    try {
      final result = await _biometricService.authenticate(
        reason: reason ?? '请验证指纹以继续使用应用',
      );
      
      print('🔐 生物识别验证结果: $result');
      
      if (result) {
        _isAuthenticated = true;
        _requireAuth = false;
        notifyListeners();
        print('✅ 验证通过，已更新状态');
      } else {
        _isAuthenticated = false;
        notifyListeners();
        print('❌ 验证失败或取消');
      }
      
      return result;
    } catch (e) {
      print('❌ 验证过程异常：$e');
      _isAuthenticated = false;
      notifyListeners();
      return false;
    }
  }

  /// 设置需要重新验证（用户退出应用时调用）
  void setRequireAuth(bool value) {
    _requireAuth = value;
    if (value) {  // 需要验证时，重置认证状态
      _isAuthenticated = false;
    }
    notifyListeners();
  }

  /// 重置认证状态
  void reset() {
    print('🔄 BiometricProvider.reset() 被调用');
    print('🔄 重置前状态: isAuthenticated=$_isAuthenticated, requireAuth=$_requireAuth');
    _isAuthenticated = false;
    _requireAuth = true;
    notifyListeners();
    print('🔄 重置后状态: isAuthenticated=$_isAuthenticated, requireAuth=$_requireAuth');
  }
}

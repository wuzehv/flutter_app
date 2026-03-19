import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';

class BiometricService {
  final LocalAuthentication _localAuth = LocalAuthentication();

  /// 检查设备是否支持生物识别
  Future<bool> canCheckBiometrics() async {
    try {
      return await _localAuth.canCheckBiometrics;
    } on PlatformException {
      return false;
    }
  }

  /// 获取可用的生物识别类型
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } on PlatformException {
      return <BiometricType>[];
    }
  }

  /// 验证指纹/面部识别
  Future<bool> authenticate({
    String reason = '请验证指纹以继续使用应用',
    bool useErrorDialogs = true,
    bool stickyAuth = true,
  }) async {
    try {
      // 首先检查是否支持生物识别
      final canCheckBiometrics = await this.canCheckBiometrics();
      print('设备生物识别支持状态：$canCheckBiometrics');
      
      if (!canCheckBiometrics) {
        print('❌ 设备不支持生物识别');
        throw Exception('设备不支持生物识别');
      }

      // 获取可用的生物识别类型
      final availableBiometrics = await getAvailableBiometrics();
      print('可用的生物识别类型：$availableBiometrics');
      
      if (availableBiometrics.isEmpty) {
        print('❌ 设备没有可用的生物识别方式');
        throw Exception('设备没有可用的生物识别方式');
      }

      print('✅ 设备支持生物识别，开始验证...');
      
      // 执行生物识别验证
      final didAuthenticate = await _localAuth.authenticate(
        localizedReason: reason,
        options: AuthenticationOptions(
          useErrorDialogs: useErrorDialogs,
          stickyAuth: stickyAuth,
          biometricOnly: true, // 只使用生物识别，不使用密码
        ),
      );

      print('验证结果：$didAuthenticate');
      return didAuthenticate;
    } on PlatformException catch (e) {
      print('❌ 生物识别失败：${e.message}');
      return false;
    } catch (e) {
      print('❌ 生物识别异常：$e');
      return false;
    }
  }

  /// 检查是否有已注册的生物识别信息
  Future<bool> isBiometricAvailable() async {
    try {
      final canCheck = await canCheckBiometrics();
      if (!canCheck) return false;

      final availableBiometrics = await getAvailableBiometrics();
      return availableBiometrics.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
}

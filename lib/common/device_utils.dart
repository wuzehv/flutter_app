import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'config.dart';

/// 设备信息工具类
/// 用于检测当前运行设备，判断是否为模拟器或调试设备
class DeviceUtils {
  static final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  
  /// 检查当前设备是否为调试设备（模拟器等）
  static Future<bool> isDebugDevice() async {
    try {
      // 先打印设备信息，方便调试
      await printDeviceInfo();
      
      String deviceId = await getDeviceId();
      print('设备 ID: $deviceId');
      print('配置的白名单列表：${Config.DEBUG_DEVICE_IDS}');
      
      // 检查是否在配置的调试设备列表中
      bool isInWhiteList = false;
      for (var debugId in Config.DEBUG_DEVICE_IDS) {
        print('检查白名单项："$debugId" vs 设备 ID: "$deviceId"');
        if (deviceId.toLowerCase().contains(debugId.trim().toLowerCase())) {
          print('✅ 匹配到白名单设备：$debugId');
          isInWhiteList = true;
          break;
        }
      }
      
      if (isInWhiteList) {
        return true;
      }
      
      // Android 模拟器检测
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        print('Android 设备型号：${androidInfo.model}');
        print('Android 指纹：${androidInfo.fingerprint}');
        
        // 通过硬件特征判断是否为模拟器
        final isEmulator = 
          androidInfo.fingerprint?.toLowerCase().contains('vbox') == true ||
          androidInfo.fingerprint?.toLowerCase().contains('test-keys') == true ||
          androidInfo.model?.toLowerCase() == 'sdk' ||
          androidInfo.model?.toLowerCase() == 'google_sdk' ||
          androidInfo.hardware?.toLowerCase() == 'vbox86' ||
          androidInfo.board?.toLowerCase() == 'goldfish' ||
          androidInfo.bootloader?.toLowerCase() == 'u-boot' ||
          androidInfo.manufacturer?.toLowerCase() == 'genymotion';
          
        if (isEmulator) {
          print('✅ 检测到 Android 模拟器：${androidInfo.model}');
          return true;
        }
      }
      
      // iOS 模拟器检测
      if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        print('iOS 设备型号：${iosInfo.model}');
        print('是否真机：${iosInfo.isPhysicalDevice}');
        
        // iOS 模拟器没有真机的某些特征
        final isSimulator = !iosInfo.isPhysicalDevice;
        if (isSimulator) {
          print('✅ 检测到 iOS 模拟器');
          return true;
        }
      }
      
      print('❌ 非白名单设备，需要指纹验证');
      return false;
    } catch (e) {
      print('❌ 检查设备类型失败：$e');
      // 如果检测失败，默认不是调试设备（需要验证）
      return false;
    }
  }
  
  /// 获取设备 ID
  static Future<String> getDeviceId() async {
    try {
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        return androidInfo.id ?? 'unknown';
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        return iosInfo.identifierForVendor ?? 'unknown';
      }
      return 'unknown';
    } catch (e) {
      print('获取设备 ID 失败：$e');
      return 'unknown';
    }
  }
  
  /// 打印设备信息（用于调试）
  static Future<void> printDeviceInfo() async {
    try {
      print('========== 设备信息 ==========');
      print('平台：${Platform.operatingSystem} ${Platform.operatingSystemVersion}');
      
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        print('品牌：${androidInfo.brand}');
        print('型号：${androidInfo.model}');
        print('设备 ID: ${androidInfo.id}');
        print('指纹：${androidInfo.fingerprint}');
        print('硬件：${androidInfo.hardware}');
        print('主板：${androidInfo.board}');
        print('引导程序：${androidInfo.bootloader}');
        print('制造商：${androidInfo.manufacturer}');
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        print('名称：${iosInfo.name}');
        print('型号：${iosInfo.model}');
        print('系统版本：${iosInfo.systemVersion}');
        print('是否真机：${iosInfo.isPhysicalDevice}');
        print('标识符：${iosInfo.identifierForVendor}');
      }
      print('============================');
    } catch (e) {
      print('打印设备信息失败：$e');
    }
  }
}

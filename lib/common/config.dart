class Config {
  static const String BASE = 'http://192.168.5.60';

  static const String UPGRADE_PORT = ':10000';
  static const String API_PORT = ':10001';

  // 是否启用指纹验证（默认 true）
  static const bool ENABLE_BIOMETRIC = true;
  
  // 调试设备列表（这些设备不需要指纹验证）
  // 可以通过设备 ID、模拟器标识等来配置
  static const List<String> DEBUG_DEVICE_IDS = [
    'UPB4.230623.005', // hp 模拟器
  ];

  static String get JENKINS_URL => BASE + API_PORT;

  static String get UPGRADE_URL => BASE + UPGRADE_PORT;
}

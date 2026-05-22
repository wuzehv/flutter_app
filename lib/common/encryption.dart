import 'dart:convert';

/// localStorage 数据加密工具
/// 使用简单的 XOR + Base64 混淆，足够防止明文暴露，且 Web 绝对兼容
class StorageEncryption {
  static const int _salt = 0x5A;

  /// 加密：XOR 混淆后 Base64 编码
  static String encrypt(String plainText) {
    final bytes = utf8.encode(plainText);
    final obfuscated = bytes.map((b) => b ^ _salt).toList();
    return base64.encode(obfuscated);
  }

  /// 解密：Base64 解码后 XOR 还原
  /// 如果解密失败（兼容旧明文数据或旧 AES 密文），直接返回原字符串
  static String decrypt(String cipherText) {
    try {
      final bytes = base64.decode(cipherText);
      final plain = bytes.map((b) => b ^ _salt).toList();
      final result = utf8.decode(plain);
      // 校验解密结果是否为 JSON（防止旧 AES 密文被 base64 解码成功但 XOR 后是乱码）
      final trimmed = result.trim();
      if (!trimmed.startsWith('{') && !trimmed.startsWith('[')) {
        throw FormatException('Not JSON');
      }
      return result;
    } catch (_) {
      // 旧数据是明文 JSON 或旧 AES 密文，直接返回原字符串让外层尝试解析
      return cipherText;
    }
  }
}

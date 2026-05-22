import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jenkins_app/common/encryption.dart';

typedef FromJson<T> = T Function(Map<String, dynamic> json);
typedef ToJson<T> = Map<String, dynamic> Function(T object);

class ObjectStore<T> {
  final String key;
  final FromJson<T> fromJson;
  final ToJson<T> toJson;

  ObjectStore({required this.key, required this.fromJson, required this.toJson});

  Future<SharedPreferences> get _prefs async => await SharedPreferences.getInstance();

  Future<void> save(String id, T obj) async {
    final prefs = await _prefs;
    final String? encrypted = prefs.getString(key);
    final String decrypted = encrypted != null ? StorageEncryption.decrypt(encrypted) : '{}';
    Map<String, dynamic> data = json.decode(decrypted);

    data[id] = toJson(obj);

    await prefs.setString(key, StorageEncryption.encrypt(json.encode(data)));
  }

  Future<List<T>> list() async {
    final prefs = await _prefs;
    final String? encrypted = prefs.getString(key);
    final String decrypted = encrypted != null ? StorageEncryption.decrypt(encrypted) : '{}';
    final Map<String, dynamic> m = json.decode(decrypted);

    return m.values.map<T>((e) => fromJson(Map<String, dynamic>.from(e))).toList();
  }

  Future<void> remove(String id) async {
    final prefs = await _prefs;
    final String? encrypted = prefs.getString(key);
    if (encrypted != null) {
      final String decrypted = StorageEncryption.decrypt(encrypted);
      final Map<String, dynamic> data = json.decode(decrypted);
      data.remove(id);
      await prefs.setString(key, StorageEncryption.encrypt(json.encode(data)));
    }
  }
}

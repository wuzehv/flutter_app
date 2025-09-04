import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

typedef FromJson<T> = T Function(Map<String, dynamic> json);
typedef ToJson<T> = Map<String, dynamic> Function(T object);

class ObjectStore<T> {
  final String key;
  final FromJson<T> fromJson;
  final ToJson<T> toJson;

  static const _storage = FlutterSecureStorage();

  ObjectStore({required this.key, required this.fromJson, required this.toJson});

  Future<void> save(String id, T obj) async {
    final String? jsonString = await _storage.read(key: key);
    Map<String, dynamic> data = jsonString != null ? json.decode(jsonString) : {};

    data[id] = toJson(obj);

    await _storage.write(key: key, value: json.encode(data));
  }

  Future<List<T>> list() async {
    final String? jsonString = await _storage.read(key: key);
    final Map<String, dynamic> m = jsonString != null ? json.decode(jsonString) : {};

    return m.values.map<T>((e) => fromJson(Map<String, dynamic>.from(e))).toList();
  }

  Future<void> remove(String id) async {
    final String? jsonString = await _storage.read(key: key);
    if (jsonString != null) {
      final Map<String, dynamic> data = json.decode(jsonString);
      data.remove(id);
      await _storage.write(key: key, value: json.encode(data));
    }
  }
}

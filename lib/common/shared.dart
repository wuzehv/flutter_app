import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

typedef FromJson<T> = T Function(Map<String, dynamic> json);
typedef ToJson<T> = Map<String, dynamic> Function(T object);

class ObjectStore<T> {
  final String key;
  final FromJson<T> fromJson;
  final ToJson<T> toJson;

  ObjectStore({required this.key, required this.fromJson, required this.toJson});

  Future<void> save(String id, T obj) async {
    final prefs = await SharedPreferences.getInstance();

    final String? jsonString = prefs.getString(key);
    Map<String, dynamic> data = jsonString != null ? json.decode(jsonString) : {};

    data[id] = toJson(obj);

    await prefs.setString(key, json.encode(data));
  }

  Future<List<T>> list() async {
    final prefs = await SharedPreferences.getInstance();
    final String? jsonString = prefs.getString(key);
    final Map<String, dynamic> m = jsonString != null ? json.decode(jsonString) : {};

    return m.values.map<T>((e) => fromJson(Map<String, dynamic>.from(e))).toList();
  }

  Future<void> remove(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final String? jsonString = prefs.getString(key);
    if (jsonString != null) {
      final Map<String, dynamic> data = json.decode(jsonString);
      data.remove(id);
      await prefs.setString(key, json.encode(data));
    }
  }
}

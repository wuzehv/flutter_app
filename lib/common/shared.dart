import 'dart:convert';
import 'package:jenkins_app/models/jenkins.dart';
import 'package:shared_preferences/shared_preferences.dart';

class JenkinsStore {
  static const String _key = 'jenkins_map';

  static Future<void> add(String id, JenkinsModel jenkins) async {
    final prefs = await SharedPreferences.getInstance();

    final String? jsonString = prefs.getString(_key);
    Map<String, dynamic> data = jsonString != null ? json.decode(jsonString) : {};
    data[id] = jenkins;
    await prefs.setString(_key, json.encode(data));
  }

  static Future<List<dynamic>> list() async {
    final prefs = await SharedPreferences.getInstance();
    final String? jsonString = prefs.getString(_key);
    final m = jsonString != null ? json.decode(jsonString) : {};
    return m.values.map((e) => JenkinsModel.fromJson(e)).toList();
  }

  static Future<void> remove(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final String? jsonString = prefs.getString(_key);
    if (jsonString != null) {
      final Map<String, dynamic> data = json.decode(jsonString);
      data.remove(id);
      await prefs.setString(_key, json.encode(data));
    }
  }
}

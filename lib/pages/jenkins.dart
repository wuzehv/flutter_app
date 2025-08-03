import 'package:dio/dio.dart';

class Jenkins {
  final String? id;
  final String remark;
  final String url;
  final String user;
  final String token;

  Jenkins({
    required this.remark,
    required this.url,
    required this.user,
    required this.token,
    this.id,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'remark': remark,
      'url': url,
      'user': user,
      'token': token,
    };
  }

  factory Jenkins.fromJson(Map<String, dynamic> json) {
    return Jenkins(
      id: json['id'],
      remark: json['remark'],
      user: json['user'],
      url: json['url'],
      token: json['token'],
    );
  }

  @override
  String toString() {
    return 'Jenkins{id: $id, remark: $remark, url: $url, user: $user, token: $token}';
  }
}

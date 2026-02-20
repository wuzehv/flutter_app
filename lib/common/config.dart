class Config {
  static const String BASE = 'http://192.168.5.60';

  static const String UPGRADE_PORT = ':10000';
  static const String API_PORT = ':10001';

  static String get JENKINS_URL => BASE + API_PORT;

  static String get UPGRADE_URL => BASE + UPGRADE_PORT;
}

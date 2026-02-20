# Jenkins工具箱

一个便捷的Jenkins和CodeUp管理工具。

## 功能特性

- 🛠️ Jenkins项目管理和构建
- 📦 CodeUp代码仓库管理
- ⚙️ 全局IP配置常量管理
- 🔄 应用自动升级
- 📱 现代化Material Design界面

## IP配置管理

所有服务地址通过常量统一管理，修改环境只需更改`Config.IS_DEV`即可。

### 配置文件位置
`lib/common/config.dart`

### 配置示例
```dart
class Config {
  // 环境开关
  static const bool IS_DEV = true; // true:开发 false:生产
  
  // 开发环境
  static const String DEV_JENKINS = 'http://192.168.18.4:8989';
  static const String DEV_UPGRADE = 'http://192.168.5.60:10000';
  
  // 生产环境
  static const String PROD_JENKINS = 'http://jenkins.prod.com:8080';
  static const String PROD_UPGRADE = 'http://upgrade.prod.com:8080';
  
  // 当前使用配置
  static String get JENKINS_URL => IS_DEV ? DEV_JENKINS : PROD_JENKINS;
  static String get UPGRADE_URL => IS_DEV ? DEV_UPGRADE : PROD_UPGRADE;
}
```

### 切换环境
只需要修改`IS_DEV`的值：
- `true` → 使用开发环境配置
- `false` → 使用生产环境配置

## 开发环境

- Flutter 3.8.1+
- Dart 3.8.1+

## 依赖库

- `dio`: HTTP客户端
- `provider`: 状态管理
- `go_router`: 路由管理
- `oktoast`: 消息提示

## 快速开始

1. 克隆项目
2. 运行 `flutter pub get`
3. 连接设备或启动模拟器
4. 运行 `flutter run`

## 项目结构

```
lib/
├── common/           # 通用工具类
│   ├── app_config.dart       # 全局配置常量
│   ├── jenkins_global.dart
│   ├── shared.dart
│   ├── util.dart
│   └── ...
├── models/           # 数据模型
│   ├── jenkins.dart
│   ├── codeup.dart
│   └── ...
├── screens/          # 页面组件
│   ├── home.dart
│   └── ...
└── main.dart         # 应用入口
```

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'biometric_provider.dart';

/// 指纹验证遮罩层组件
/// 当需要验证时显示，验证通过后自动消失
class BiometricOverlay extends StatefulWidget {
  final Widget child;

  const BiometricOverlay({super.key, required this.child});

  @override
  State<BiometricOverlay> createState() => _BiometricOverlayState();
}

class _BiometricOverlayState extends State<BiometricOverlay> with WidgetsBindingObserver {
  bool _hasTriggered = false;

  @override
  void initState() {
    super.initState();
    print('🔵 BiometricOverlay initState');
    _hasTriggered = false;
    WidgetsBinding.instance.addObserver(this);
    
    // 首次启动时触发验证
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuth();
    });
  }
  
  void _checkAuth() {
    if (!mounted) return;
    
    final provider = context.read<BiometricProvider>();
    print('🔵 _checkAuth: isLoading=${provider.isLoading}, isAuthenticated=${provider.isAuthenticated}');
    
    if (provider.isLoading) {
      // 等待初始化完成
      Future.delayed(Duration(milliseconds: 100), _checkAuth);
      return;
    }
    
    if (provider.isDebugDevice) {
      provider.setRequireAuth(false);
      return;
    }
    
    if (provider.requireAuth && !provider.isAuthenticated && !_hasTriggered) {
      _hasTriggered = true;
      print('🔐 触发指纹验证');
      _triggerAuthentication();
    }
  }
  
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    print('📱 BiometricOverlay 生命周期状态: $state');
    
    if (state == AppLifecycleState.paused) {
      print('📱 应用进入后台 (paused)');
    } else if (state == AppLifecycleState.inactive) {
      print('📱 应用变为非活动 (inactive)');
    } else if (state == AppLifecycleState.hidden) {
      print('📱 应用被隐藏 (hidden)');
    } else if (state == AppLifecycleState.detached) {
      print('📱 应用被分离 (detached) - 可能被系统回收');
    } else if (state == AppLifecycleState.resumed) {
      // 应用从后台恢复
      print('📱 应用 resumed');
      // 如果应用被系统回收(detached)后重新启动，BiometricOverlay 会重新创建
      // 如果应用只是进入后台(paused)后恢复，保持当前状态
    }
  }

  Future<void> _triggerAuthentication() async {
    if (!mounted) {
      print('❌ _triggerAuthentication: widget 未挂载');
      return;
    }
    
    final provider = context.read<BiometricProvider>();
    print('🔐 _triggerAuthentication: 开始调用 provider.authenticate()');

    // 执行验证（不检查设备是否支持，直接调用）
    try {
      final success = await provider.authenticate();
      print('🔐 _triggerAuthentication: 验证结果 success=$success');

      if (!success && mounted) {
        // 验证失败，退出应用
        print('❌ 验证失败，显示退出对话框');
        _showFailureDialog();
      }
    } catch (e) {
      // 如果设备不支持生物识别，也视为验证失败
      print('❌ 指纹验证异常：$e');
      if (mounted) {
        _showUnsupportedDialog();
      }
    }
  }

  void _showFailureDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => WillPopScope(
        onWillPop: () async => false,
        child: AlertDialog(
          title: const Text('验证失败'),
          content: const Text('指纹验证失败或已取消，为了安全考虑，应用将关闭。'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                SystemNavigator.pop();
              },
              child: const Text('确定'),
            ),
          ],
        ),
      ),
    );
  }

  void _showUnsupportedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => WillPopScope(
        onWillPop: () async => false,
        child: AlertDialog(
          title: const Text('设备不支持'),
          content: const Text('该设备不支持指纹验证，为了安全考虑，应用将无法使用。'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                SystemNavigator.pop();
              },
              child: const Text('确定'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BiometricProvider>(
      builder: (context, provider, child) {
        print('🎨 BiometricOverlay build: requireAuth=${provider.requireAuth}, isAuthenticated=${provider.isAuthenticated}, isLoading=${provider.isLoading}');
        
        // 如果需要验证且未通过，显示遮罩层
        if (provider.requireAuth && !provider.isAuthenticated) {
          print('🔒 显示验证遮罩层');
          return Scaffold(
            body: GestureDetector(
              // 点击屏幕也可以触发验证（备用方案）
              onTap: () {
                print('👆 用户点击屏幕，尝试触发验证');
                _hasTriggered = false;
                _checkAuth();
              },
              child: Container(
                color: Colors.black.withOpacity(0.9),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.fingerprint,
                        size: 100,
                        color: Colors.white.withOpacity(0.8),
                      ),
                      const SizedBox(height: 30),
                      Text(
                        '请验证指纹',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 15),
                      Text(
                        '点击屏幕唤起指纹验证',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 14,
                        ),
                      ),
                      if (provider.isLoading) ...[
                        const SizedBox(height: 30),
                        const CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        // 验证通过或不需要验证，显示正常内容
        print('✅ 显示正常内容');
        return widget.child;
      },
    );
  }
}

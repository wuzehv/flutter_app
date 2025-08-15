import 'package:flutter/widgets.dart';

class LoadingProvider extends ChangeNotifier {
  bool _loading = false;

  bool get loading => _loading;

  void show() {
    _loading = true;
    notifyListeners();
  }

  void hide() {
    _loading = false;
    notifyListeners();
  }
}

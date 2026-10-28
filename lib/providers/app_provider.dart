/// State management utama aplikasi.
library app_provider;

import 'package:flutter/foundation.dart';

class AppProvider extends ChangeNotifier {
  String _currentBusinessName = 'Dr4ox Motor';

  String get currentBusinessName => _currentBusinessName;

  void setBusinessName(String name) {
    _currentBusinessName = name;
    notifyListeners();
  }
}

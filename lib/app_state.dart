// Shared in-memory app state for the patient profile picture.
// Using a ValueNotifier so all listening widgets rebuild automatically.
import 'package:flutter/foundation.dart';

class AppState {
  AppState._();
  static final profileImagePath = ValueNotifier<String?>(null);
}

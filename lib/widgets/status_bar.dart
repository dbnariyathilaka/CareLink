import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Makes the system status bar transparent so it blends into whatever this
/// screen actually paints at the top, with icons/text in [iconBrightness]
/// for contrast — [Brightness.dark] icons for a light top, [Brightness.light]
/// icons for a dark top.
///
/// Call once from `initState()` on stateful screens (cheap, and avoids
/// re-asserting on every animation-driven rebuild); call at the top of
/// `build()` on stateless screens (which only rebuild on navigation, not
/// per-frame).
void setStatusBarStyle(Brightness iconBrightness) {
  SystemChrome.setSystemUIOverlayStyle(
    iconBrightness == Brightness.dark
        ? SystemUiOverlayStyle.dark.copyWith(statusBarColor: Colors.transparent)
        : SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent),
  );
}

import 'package:flutter/material.dart';

/// A [TextEditingController] that never draws the IME "composing" underline
/// under text while it's being typed — the pale line some keyboards (Gboard's
/// predictive text, spell-check, etc.) leave under a word mid-composition.
/// Flutter draws that underline itself whenever the controller reports a
/// valid composing range; forcing [withComposing] to false here is the
/// standard, supported way to suppress it everywhere without touching every
/// field's own decoration.
class NoUnderlineTextEditingController extends TextEditingController {
  NoUnderlineTextEditingController({super.text});

  NoUnderlineTextEditingController.fromValue(super.value) : super.fromValue();

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    return super.buildTextSpan(context: context, style: style, withComposing: false);
  }
}

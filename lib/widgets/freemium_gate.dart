import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';

class FreemiumGate extends StatelessWidget {
  final Widget child;
  final bool isLocked;
  final double? delta;

  const FreemiumGate({
    super.key,
    required this.child,
    this.isLocked = true,
    this.delta,
  });

  @override
  Widget build(BuildContext context) {
    // FORCE UNLOCK - NO EXCEPTIONS
    return child; // TODO: REVERT BEFORE PRODUCTION
  }
}

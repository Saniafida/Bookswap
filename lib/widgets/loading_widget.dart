import 'package:flutter/material.dart';
import 'premium_loading.dart';

class LoadingWidget extends StatelessWidget {
  final String? message;
  final double size;

  const LoadingWidget({super.key, this.message, this.size = 24});

  @override
  Widget build(BuildContext context) {
    return PremiumLoading(message: message, size: size);
  }
}

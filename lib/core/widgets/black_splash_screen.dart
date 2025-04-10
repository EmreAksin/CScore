import 'package:flutter/material.dart';

class BlackSplashScreen extends StatelessWidget {
  final Widget child;

  const BlackSplashScreen({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(color: Colors.black, child: child);
  }
}

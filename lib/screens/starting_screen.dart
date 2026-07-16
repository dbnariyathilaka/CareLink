import 'dart:async';
import 'package:flutter/material.dart';

class StartingScreen extends StatefulWidget {
  const StartingScreen({super.key});

  @override
  State<StartingScreen> createState() => _StartingScreenState();
}

class _StartingScreenState extends State<StartingScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(seconds: 5), () {
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/welcome');
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // The design is based on width=412 and height=917.
    // We position the background shapes and icons relative to edges to support different screens nicely.
    return Scaffold(
      backgroundColor: const Color(0xFF0D9488), // Teal background
      body: Stack(
        children: [
          // Ellipse 1 (top-right): x=340, y=-60, size=120x120
          Positioned(
            top: -60,
            right: -48, // 412 - 340 - 120 = -48
            child: _buildBackgroundCircle(),
          ),

          // Ellipse 2 (middle-left): x=-50, y=190, size=120x120
          Positioned(
            top: 190,
            left: -50,
            child: _buildBackgroundCircle(),
          ),

          // Ellipse 3 (bottom-right): x=323, y=667, size=120x120
          Positioned(
            bottom: 130, // 917 - 667 - 120 = 130
            right: -31,  // 412 - 323 - 120 = -31
            child: _buildBackgroundCircle(),
          ),

          // Plus Icon 1 (Group 2): x=140, y=120, size=38x38
          Positioned(
            top: 120,
            left: 140,
            width: 38,
            height: 38,
            child: _buildPlusIcon(),
          ),

          // Plus Icon 2 (Group 3): x=333, y=212, size=38x38
          Positioned(
            top: 212,
            right: 41, // 412 - 333 - 38 = 41
            width: 38,
            height: 38,
            child: _buildPlusIcon(),
          ),

          // Plus Icon 3 (Group 1): x=70, y=689, size=38x38
          Positioned(
            bottom: 190, // 917 - 689 - 38 = 190
            left: 70,
            width: 38,
            height: 38,
            child: _buildPlusIcon(),
          ),

          // Centered Text
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'CareLink',
                  style: TextStyle(
                    fontFamily: 'Courier', // Serif/monospace look from Figma
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFF8FAFC), // White/very light teal
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Smart Match',
                  style: TextStyle(
                    fontFamily: 'Courier',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF06291F), // Dark teal/green
                    letterSpacing: 4.0,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackgroundCircle() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: const Color(0xFF2DD4BF).withOpacity(0.24), // Light teal with opacity
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildPlusIcon() {
    return const Center(
      child: Icon(
        Icons.add,
        color: Color(0xFF2DD4BF),
        size: 32,
      ),
    );
  }
}

import 'dart:async';
import 'package:flutter/material.dart';

class StartingScreen extends StatefulWidget {
  const StartingScreen({super.key});

  @override
  State<StartingScreen> createState() => _StartingScreenState();
}

class _StartingScreenState extends State<StartingScreen> {
  Timer? _timer;
  int _currentScreen = 1;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _currentScreen = 2;
        });
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
    switch (_currentScreen) {
      case 1:
        return _buildScreen1();
      case 2:
        return _buildScreen2();
      case 3:
        return _buildScreen3();
      default:
        return _buildScreen1();
    }
  }

  Widget _buildScreen1() {
    return Scaffold(
      backgroundColor: const Color(0xFF06402B), // Dark green background
      body: Center(
        child: Image.asset(
          'assets/images/splash_logo.png',
          width: 300,
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  Widget _buildScreen2() {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFA96F3C),
              Color(0xFFF4D3B6),
              Color(0xFFFFFFFF),
            ],
            stops: [0.0, 0.80, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 20),
              // Title
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'Care that comes to you',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'serif',
                    fontSize: 44,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF06402B),
                    height: 1.1,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Subtitle
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'Find trusted caregivers matched to your needs',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF06402B),
                    height: 1.2,
                  ),
                ),
              ),
              const Spacer(),
              // Redesigned pre-masked single combined image with soft blur fade mask
              ShaderMask(
                shaderCallback: (rect) {
                  return const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black,
                      Colors.black,
                      Colors.transparent,
                    ],
                    stops: [0.0, 0.15, 0.85, 1.0],
                  ).createShader(rect);
                },
                blendMode: BlendMode.dstIn,
                child: Image.asset(
                  'assets/images/screen2_obj.png',
                  fit: BoxFit.contain,
                  height: 380,
                ),
              ),
              const Spacer(),
              // Next Button
              GestureDetector(
                onTap: () {
                  setState(() {
                    _currentScreen = 3;
                  });
                },
                child: Container(
                  width: 296,
                  height: 60,
                  decoration: BoxDecoration(
                    color: const Color(0xFF06402B),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    'Next',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 36),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScreen3() {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFC8B65E),
              Color(0xFFFBEB9C),
              Color(0xFFFDF5CE),
              Color(0xFFFFFFFF),
            ],
            stops: [0.0, 0.17, 0.88, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 20),
              // Title
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'Matched, not searched',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'serif',
                    fontSize: 44,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF06402B),
                    height: 1.1,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Subtitle
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'We rank caregivers by skills, location, and availability.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF06402B),
                    height: 1.2,
                  ),
                ),
              ),
              const Spacer(),
              // Image Stack with soft blur fade mask
              ShaderMask(
                shaderCallback: (rect) {
                  return const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black,
                      Colors.black,
                      Colors.transparent,
                    ],
                    stops: [0.0, 0.15, 0.85, 1.0],
                  ).createShader(rect);
                },
                blendMode: BlendMode.dstIn,
                child: SizedBox(
                  height: 380,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Image.asset(
                        'assets/images/screen3_bg.png',
                        fit: BoxFit.cover,
                        height: 360,
                      ),
                      Image.asset(
                        'assets/images/screen3_obj.png',
                        fit: BoxFit.contain,
                        height: 380,
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              // Next Button
              GestureDetector(
                onTap: () {
                  Navigator.pushReplacementNamed(context, '/welcome');
                },
                child: Container(
                  width: 296,
                  height: 60,
                  decoration: BoxDecoration(
                    color: const Color(0xFF06402B),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    'Next',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 36),
            ],
          ),
        ),
      ),
    );
  }
}

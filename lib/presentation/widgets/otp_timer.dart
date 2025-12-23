import 'dart:async';
import 'package:flutter/material.dart';

class OtpTimer extends StatefulWidget {
  final VoidCallback onExpired;

  const OtpTimer({Key? key, required this.onExpired}) : super(key: key);

  @override
  State<OtpTimer> createState() => _OtpTimerState();
}

class _OtpTimerState extends State<OtpTimer> {
  static const int totalSeconds = 5 * 60; // 5 minutes
  int secondsLeft = totalSeconds;
  Timer? _timer;
  bool expired = false;

  @override
  void initState() {
    super.initState();
    start();
  }

  void start() {
    expired = false;
    secondsLeft = totalSeconds;
    _timer?.cancel();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (secondsLeft > 0) {
        setState(() => secondsLeft--);
      } else {
        timer.cancel();
        setState(() => expired = true);
        widget.onExpired();
      }
    });
  }

  void restart() {
    start();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (expired) {
      return const Text(
        'OTP expired',
        style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
      );
    }

    final min = secondsLeft ~/ 60;
    final sec = secondsLeft % 60;

    return Text(
      'OTP expires in ${min.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}',
      style: const TextStyle(
        color: Colors.red,
        fontWeight: FontWeight.w600,
        fontSize: 16,
      ),
    );
  }
}

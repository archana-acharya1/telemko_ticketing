import 'package:flutter/material.dart';

import '../../widgets/otp_timer.dart';

class OtpScreen extends StatefulWidget {
  const OtpScreen({Key? key}) : super(key: key);

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final TextEditingController otpController = TextEditingController();
  final GlobalKey _timerKey = GlobalKey();

  bool isExpired = false;

  void onOtpExpired() {
    setState(() => isExpired = true);
  }

  void verifyOtp() {
    if (otpController.text.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Enter OTP')));
      return;
    }

    if (isExpired) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('OTP expired')));
      return;
    }

    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('OTP verified (mock)')));
  }

  void resendOtp() {
    setState(() => isExpired = false);
    ( _timerKey.currentState as dynamic )?.restart();

    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('OTP resent')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('OTP Verification')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter the OTP sent to your mobile number',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: otpController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: const InputDecoration(
                labelText: 'OTP',
                border: OutlineInputBorder(),
                counterText: '',
              ),
            ),

            const SizedBox(height: 12),

            // COUNTDOWN SHOWN TO USER
            OtpTimer(
              key: _timerKey,
              onExpired: onOtpExpired,
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isExpired ? null : verifyOtp,
                child: const Text('Verify OTP'),
              ),
            ),

            if (isExpired)
              Center(
                child: TextButton(
                  onPressed: resendOtp,
                  child: const Text('Resend OTP'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

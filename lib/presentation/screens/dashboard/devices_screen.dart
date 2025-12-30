import 'package:flutter/material.dart';

import '../../../core/theme/app_text_styles.dart';

class DevicesScreen extends StatelessWidget {
  const DevicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    print("[DevicesScreen] Screen loaded");
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "New Devices",
          style: AppTextStyles.headline2.copyWith(color: Colors.white),
        ),
        centerTitle: true,
      ),

      body: Center(
        child: Text(
          "Devices Page",
          style: theme.textTheme.titleLarge!.copyWith(
            fontWeight: FontWeight.w600,
            color: cs.onSurface,
          ),
        ),
      ),
    );
  }
}

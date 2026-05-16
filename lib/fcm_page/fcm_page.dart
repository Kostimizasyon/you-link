import 'package:flutter/material.dart';
import 'package:you_link/fcm_page/components/auth_info.dart';
import 'package:you_link/fcm_page/components/fcm_refresh_button.dart';
import 'components/worker_clock.dart';

class FcmPage extends StatelessWidget {
  const FcmPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          AuthInfo(),
          FcmRefreshButton(),
          WorkerClock()
        ],
      ),
    );
  }
}

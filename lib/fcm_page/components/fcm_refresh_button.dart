import 'package:flutter/material.dart';
import 'package:you_link/workers/fcm_workers.dart' show sendFCM;
import '../../user_provider/user_provider.dart';

class FcmRefreshButton extends StatelessWidget {
  const FcmRefreshButton({super.key});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
        onPressed: () async {
          final driveApi = await UserProvider.getWorkerDriveApi();
          if (driveApi == null) {
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(content: Text("Error with drive API, try again"),backgroundColor: Colors.red)
            );
          }
          bool result = await sendFCM(driveApi);

          if (result) {
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Sucesfully sent FCM!"),backgroundColor: Colors.green,)
            );
          }
          else {
            debugPrint("Couldnt send fcm");
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Couldn't send FCM token"),backgroundColor: Colors.red)
            );
          }

        },
        child: Text("Refresh FCM")
    );
  }
}

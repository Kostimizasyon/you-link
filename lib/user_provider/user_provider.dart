import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:you_link/google_auth_client/google_auth_client.dart';

class UserProvider extends ChangeNotifier {
  static const List<String> _scopes = [drive.DriveApi.driveScope];
  static const String _serverClientId = "66420181337-92t39cohuvuj1eccf9fhk94eb56v8onl.apps.googleusercontent.com";

  // static cache for worker use
  static drive.DriveApi? _cachedWorkerDriveApi;

  GoogleSignInAccount? _currentUser;
  drive.DriveApi? _driveApi;

  drive.DriveApi? get driveApi => _driveApi;
  GoogleSignInAccount? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null && _driveApi != null;

  static Future<void> initialize() async {
    await GoogleSignIn.instance.initialize(
      serverClientId: _serverClientId,
    );
  }

  Future<void> signIn() async {
    try {
      final account = await GoogleSignIn.instance.authenticate();
      _currentUser = account;

      // explicitly authorize scopes during sign in
      await account.authorizationClient.authorizeScopes(_scopes);

      final authHeaders = await account.authorizationClient
          .authorizationHeaders(_scopes);
      if (authHeaders == null) return;

      final client = GoogleAuthClient(authHeaders);
      _driveApi = drive.DriveApi(client);
      _cachedWorkerDriveApi = _driveApi;

      notifyListeners();
    } catch (e) {
      debugPrint('Sign in error: $e');
    }
  }

  static Future<drive.DriveApi?> getWorkerDriveApi() async {
    if (_cachedWorkerDriveApi != null) {
      debugPrint('Worker: using cached DriveApi');
      return _cachedWorkerDriveApi;
    }

    try {
      await GoogleSignIn.instance.initialize(
        serverClientId: _serverClientId,
      );

      debugPrint('Worker: initialized, attempting lightweight auth');

      final completer = Completer<GoogleSignInAccount?>();
      final sub = GoogleSignIn.instance.authenticationEvents.listen((event) {
        debugPrint('Worker: got auth event: ${event.runtimeType}');
        if (event is GoogleSignInAuthenticationEventSignIn) {
          completer.complete(event.user);
        } else {
          completer.complete(null);
        }
      });

      GoogleSignIn.instance.attemptLightweightAuthentication();
      debugPrint('Worker: waiting for auth event...');

      final account = await completer.future.timeout(
        Duration(seconds: 10),
        onTimeout: () {
          debugPrint('Worker: auth timed out');
          return null;
        },
      );

      await sub.cancel();

      if (account == null) {
        debugPrint('Worker: account is null');
        return null;
      }

      debugPrint('Worker: got account ${account.email}');

      final authHeaders = await account.authorizationClient
          .authorizationHeaders(_scopes);

      if (authHeaders == null) {
        debugPrint('Worker: authHeaders is null');
        return null;
      }

      final client = GoogleAuthClient(authHeaders);
      _cachedWorkerDriveApi = drive.DriveApi(client);
      return _cachedWorkerDriveApi;
    } catch (e) {
      debugPrint('Worker relogin error: $e');
      return null;
    }
  }

  Future<void> signOut() async {
    await GoogleSignIn.instance.signOut();
    _currentUser = null;
    _driveApi = null;
    _cachedWorkerDriveApi = null;  // clear cache on signout
    notifyListeners();
  }
}
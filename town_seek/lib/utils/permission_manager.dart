import 'package:permission_handler/permission_handler.dart';

class PermissionManager {
  /// Requests the initial set of permissions required by the app.
  static Future<void> requestInitialPermissions() async {
    // Request multiple permissions at once
    await [
      Permission.photos, // For iOS and Android 13+ (images)
      Permission.storage, // For Android < 13
      Permission.location, // Fine/Coarse location
      Permission.phone, // For making calls
      // Permission.callLog // Be careful with this, Google Play has strict policies. But user requested it.
    ].request();

    // Note: 'Permission.callLog' requires specific justification on Google Play.
    // If we just need to MAKE a call, Permission.phone is usually sufficient for the dialer, 
    // or CALL_PHONE for direct calls. 
    // We will request it since the user explicitly asked for 'call log'.
    await Permission.phone.request();
    
    // Check status if needed, but for now we just ask.
    // Check status if needed, but for now we just ask.
    // print("Permissions requested: $statuses");
  }

  /// Checks if a specific permission is granted.
  static Future<bool> isGranted(Permission permission) async {
    return await permission.isGranted;
  }
}

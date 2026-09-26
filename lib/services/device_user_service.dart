import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';

class DeviceUserService {
  static const String _deviceIdKey = 'device_user_id';
  static String? _cachedUserId;

  /// Returns the persistent device user ID for this single-user installation.
  static Future<String> getDeviceId() async {
    if (_cachedUserId != null) return _cachedUserId!;

    try {
      final prefs = await SharedPreferences.getInstance();
      String? storedId = prefs.getString(_deviceIdKey);

      if (storedId == null || storedId.isEmpty) {
        storedId = _generateUuidV4();
        await prefs.setString(_deviceIdKey, storedId);
      }

      _cachedUserId = storedId;
      return storedId;
    } catch (_) {
      _cachedUserId ??= _generateUuidV4();
      return _cachedUserId!;
    }
  }

  /// Generates a valid random UUID v4 string compliant with PostgreSQL UUID format.
  static String _generateUuidV4() {
    final Random random = Random.secure();
    final List<int> values = List<int>.generate(16, (_) => random.nextInt(256));

    // Set version to 4 (random)
    values[6] = (values[6] & 0x0f) | 0x40;
    // Set variant to IETF (10xx)
    values[8] = (values[8] & 0x3f) | 0x80;

    final StringBuffer buffer = StringBuffer();
    for (int i = 0; i < 16; i++) {
      if (i == 4 || i == 6 || i == 8 || i == 10) {
        buffer.write('-');
      }
      buffer.write(values[i].toRadixString(16).padLeft(2, '0'));
    }
    return buffer.toString();
  }
}

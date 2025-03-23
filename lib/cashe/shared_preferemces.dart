import 'dart:convert';
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:odoo_rpc/odoo_rpc.dart';
import 'package:flutter/foundation.dart'; // Add this import for debugPrint

class SharedPreferencesUtil {
  static const String _sessionKey = 'odoo_session';

  static Future<void> saveSession(OdooSession session) async {
    final prefs = await SharedPreferences.getInstance();
    final sessionJson = session.toJson(); // Convert OdooSession to Map
    final sessionString =
        jsonEncode(sessionJson); // Convert Map to valid JSON string
    await prefs.setString(_sessionKey, sessionString); // Save JSON string
  }

  static Future<OdooSession?> getSession() async {
    final prefs = await SharedPreferences.getInstance();
    final sessionString = prefs.getString(_sessionKey);
    if (sessionString != null) {
      try {
        final sessionJson =
            jsonDecode(sessionString); // Decode JSON string to Map
        return OdooSession.fromJson(sessionJson); // Convert Map to OdooSession
      } catch (e) {
        // Use a logging framework instead of print
        debugPrint('Error decoding JSON: $e');
        print('Error decoding JSON: $e');
        return null;
      }
    }
    return null;
  }

  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionKey);
  }
}

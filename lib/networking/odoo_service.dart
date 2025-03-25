import 'package:odoo_rpc/odoo_rpc.dart';
import 'dart:convert';

class OdooRpcService {
  static final OdooRpcService _instance = OdooRpcService._internal();
  factory OdooRpcService() => _instance;
  OdooRpcService._internal();

  final OdooClient client = OdooClient("https://elmasa-eg.com");
  String _dbName = "testIV";
  int? _userId;
  String? _sessionId;

  /// **1. Login to Odoo**
  Future<bool> login(String username, String password) async {
    try {
      final response = await client.authenticate(_dbName, username, password);
      _userId = response.userId;
      _sessionId = response.id;
      print("Login successful! User ID: $_userId");
      return true;
    } catch (e) {
      print("Login failed: $e");
      return false;
    }
  }

  Future<dynamic> callKw(Map<String, dynamic> params) async {
    try {
      print("Sending Odoo RPC request: ${jsonEncode(params)}");
      final response = await client.callKw(params);
      print("Received Odoo RPC response: ${jsonEncode(response)}");
      return response;
    } on OdooException catch (e) {
      print("OdooException: ${e.message}");
      throw Exception("Odoo RPC Error: ${e.message}");
    } catch (e) {
      print("Unexpected Error: $e");
      throw Exception("callKw failed: $e");
    }
  }

  Future<List<dynamic>> fetchMoves(List<dynamic> moveIds) async {
    try {
      final response = await client.callKw({
        'model': 'stock.move',
        'method': 'search_read',
        'args': [
          [
            ['id', 'in', moveIds]
          ]
        ],
        'kwargs': {
          'fields': [
            'id',
            'product_id',
            'product_qty',
            'product_uom',
            'quantity'
          ]
        }
      });
      return response;
    } catch (e) {
      print("Error fetching move details: $e");
      return [];
    }
  }

  Future<List<dynamic>> fetchRecords(
    String model,
    List domain,
    List<String> fields,
  ) async {
    try {
      print("Fetching records from model: $model");
      print("Domain: ${jsonEncode(domain)}");
      print("Fields: ${fields.join(", ")}");

      final response = await client.callKw({
        'model': model,
        'method': 'search_read',
        'args': [domain],
        'kwargs': {
          'fields': fields,
        },
      });

      if (response is List) {
        print("Fetched ${response.length} records");
        return response;
      } else {
        throw Exception(
            "Invalid response format: Expected List, got ${response.runtimeType}");
      }
    } catch (e) {
      print("Error fetching records: $e");
      throw Exception("Failed to fetch records: $e");
    }
  }

  Future<int?> createRecord(String model, Map<String, dynamic> values) async {
    try {
      print("Creating record in model: $model");
      print("Record data: ${jsonEncode(values)}");

      final response = await client.callKw({
        'model': model,
        'method': 'create',
        'args': [values],
        'kwargs': {},
      });

      if (response is int) {
        print("Record created successfully with ID: $response");
        return response;
      } else {
        throw Exception(
            "Invalid response format: Expected int, got ${response.runtimeType}");
      }
    } on OdooException catch (e) {
      print("OdooException while creating record: ${e.message}");
      throw Exception("Failed to create record: ${e.message}");
    } catch (e) {
      print("Unexpected error while creating record: $e");
      throw Exception("Failed to create record: $e");
    }
  }

  Future<bool> updateRecord(
      String model, int id, Map<String, dynamic> values) async {
    try {
      print('Updating record in Odoo:');
      print('Model: $model');
      print('ID: $id');
      print('Values: $values');

      final response = await client.callKw({
        'model': model,
        'method': 'write',
        'args': [
          [id],
          values,
        ],
      });

      print('Update response: $response');
      return response == true;
    } catch (e) {
      print('Error updating record: $e');
      throw Exception('Error updating record: $e');
    }
  }

  Future<bool> deleteRecord(String model, int id) async {
    try {
      final response = await client.callKw({
        'model': model,
        'method': 'unlink',
        'args': [
          [id]
        ]
      });

      return response == true;
    } catch (e) {
      print("Error deleting record: $e");
      return false;
    }
  }

  Future<void> logout() async {
    try {
      print("Logging out user: $_userId");
      await client.destroySession();
      _userId = null;
      _sessionId = null;
      print("User logged out successfully.");
    } catch (e) {
      print("Error during logout: $e");
      throw Exception("Failed to logout: $e");
    }
  }
}

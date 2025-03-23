import 'package:odoo_rpc/odoo_rpc.dart';

class OdooRpcService {
  static final OdooRpcService _instance = OdooRpcService._internal();
  factory OdooRpcService() => _instance;
  OdooRpcService._internal();

  final OdooClient client = OdooClient("http://192.168.1.220:8069");
  String _dbName = "base";
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
      return await client.callKw(params);
    } catch (e) {
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
      String model, List domain, List<String> fields) async {
    try {
      final response = await client.callKw({
        'model': model,
        'method': 'search_read',
        'args': [domain],
        'kwargs': {'fields': fields}
      });

      return response;
    } catch (e) {
      print("Error fetching records: $e");
      return [];
    }
  } //read

  Future<int?> createRecord(String model, Map<String, dynamic> values) async {
    try {
      final response = await client.callKw({
        'model': model,
        'method': 'create',
        'args': [values],
        'kwargs': {},
      });
      return response as int?;
    } catch (e) {
      print("Error creating record: $e");
      return null;
    }
  } //creat

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
  } //delet

  void logout() {
    client.destroySession();
    _userId = null;
    _sessionId = null;
    print("User logged out.");
  }
}

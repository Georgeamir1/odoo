import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:odoo/networking/odoo_service.dart';

// States
abstract class CashReceiptState {}

class CashReceiptInitial extends CashReceiptState {}

class CashReceiptLoading extends CashReceiptState {}

class CashReceiptLoaded extends CashReceiptState {
  final List<dynamic> receipts;
  CashReceiptLoaded(this.receipts);
}

class CashReceiptError extends CashReceiptState {
  final String message;
  CashReceiptError(this.message);
}

class CashReceiptCubit extends Cubit<CashReceiptState> {
  final OdooRpcService _odooService;

  CashReceiptCubit(this._odooService) : super(CashReceiptInitial());

  Future<void> fetchReceipts() async {
    emit(CashReceiptLoading());

    try {
      final userData = await _odooService.getCurrentUser();
      if (userData == null) {
        emit(CashReceiptError('User data not found'));
        return;
      }

      final receipts = await _odooService.fetchRecords(
        'account.payment',
        [
          ['journal_id', '=', 7], // Cash journal
          ['payment_type', '=', 'inbound'],
          ['create_uid', '=', userData['id']], // Filter by logged-in user
        ],
        [
          'id',
          'name',
          'amount',
          'date',
          'partner_id',
          'state',
        ],
      );

      emit(CashReceiptLoaded(receipts));
    } catch (e) {
      emit(CashReceiptError(e.toString()));
    }
  }

  Future<void> validatePayment(int paymentId) async {
    try {
      await _odooService.callKw({
        'model': 'account.payment',
        'method': 'action_validate',
        'args': [
          [paymentId]
        ],
        'kwargs': {}
      });

      // Refresh the receipts list after validation
      await fetchReceipts();
    } catch (e) {
      print(e);
      throw Exception('Failed to validate payment: ${e.toString()}');
    }
  }

  Future<void> ConfermPayment(int paymentId) async {
    try {
      await _odooService.callKw({
        'model': 'account.payment',
        'method': 'action_post',
        'args': [
          [paymentId]
        ],
        'kwargs': {}
      });

      // Refresh the receipts list after validation
      await fetchReceipts();
    } catch (e) {
      print(e);
      throw Exception('Failed to validate payment: ${e.toString()}');
    }
  }

  Future<void> createCashReceipt({
    required String customerId,
    required double amount,
  }) async {
    try {
      if (amount <= 0) {
        throw Exception('Amount must be greater than zero');
      }

      final userData = await _odooService.getCurrentUser();
      if (userData == null) {
        throw Exception('User data not found');
      }

      // Retrieve posted invoices for the customer
      final invoices = await _odooService.fetchRecords(
        'account.move',
        [
          ['partner_id', '=', int.parse(customerId)],
          ['state', '=', 'posted'],
          ['move_type', '=', 'out_invoice'],
        ],
        ['id', 'amount_residual'],
      );

      if (invoices.isEmpty) {
        throw Exception('No posted invoices found for the customer.');
      }

      // Create payment directly
      final paymentId = await _odooService.callKw({
        'model': 'account.payment',
        'method': 'create',
        'args': [
          {
            'payment_type': 'inbound',
            'partner_type': 'customer',
            'partner_id': int.parse(customerId),
            'amount': amount,
            'journal_id': 7, // Cash journal
            'payment_method_line_id': 1,
            'state': 'draft',
          }
        ],
        'kwargs': {},
      });

      if (paymentId == null) {
        throw Exception('Failed to create payment');
      }

      // Post the payment
      try {
        await _odooService.callKw({
          'model': 'account.payment',
          'method': 'action_post',
          'args': [
            [paymentId]
          ],
          'kwargs': {}
        });

        // Refresh the receipts list after posting
        await fetchReceipts();
      } catch (e) {
        print(e);
        throw Exception('Failed to post payment: ${e.toString()}');
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }
}

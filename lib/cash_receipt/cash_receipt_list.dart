import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lottie/lottie.dart';
import 'package:odoo/localization.dart';
import 'package:odoo/networking/odoo_service.dart';
import '../home/home_ui.dart';
import 'cash_receipt_cubit.dart';
import 'cash_receipt_details.dart';
import 'new_cash_receipt.dart';

class CashReceiptListPage extends StatelessWidget {
  const CashReceiptListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => CashReceiptCubit(OdooRpcService())..fetchReceipts(),
      child: WillPopScope(
        onWillPop: () async {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => HomePage(
                changeLanguage: (String languageCode) {
                  // You could also update and save the language preference here if needed.
                  Localizations.localeOf(context).languageCode;
                },
              ),
            ),
          );
          return false;
        },
        child: Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            iconTheme: const IconThemeData(color: Colors.white),
            title: Text(
              AppLocalizations.of(context).cash_receipts,
              style: const TextStyle(color: Colors.white),
            ),
            centerTitle: true,
            elevation: 0,
            flexibleSpace: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF714B67),
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(25),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
            ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NewCashReceiptScreen(),
                ),
              );
            },
            backgroundColor: const Color(0xFF714B67),
            child: const Icon(Icons.add, color: Colors.white),
          ),
          body: BlocConsumer<CashReceiptCubit, CashReceiptState>(
            listener: (context, state) {
              if (state is CashReceiptError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(state.message)),
                );
              }
            },
            builder: (context, state) {
              if (state is CashReceiptLoading) {
                return Center(
                  child: Lottie.asset('assets/images/loading3.json',
                      height: 200, width: 200),
                );
              }
              if (state is CashReceiptError) {
                return Center(child: Text(state.message));
              }
              if (state is CashReceiptLoaded) {
                if (state.receipts.isEmpty) {
                  return Center(
                    child: Text(AppLocalizations.of(context).no_receipts_found),
                  );
                }
                return _buildReceiptList(context, state.receipts);
              }
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildReceiptList(BuildContext context, List<dynamic> receipts) {
    return ListView.builder(
      itemCount: receipts.length,
      itemBuilder: (context, index) {
        final receipt = receipts[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          elevation: 2,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CashReceiptDetailsPage(
                    receiptId: receipt['id'],
                  ),
                ),
              );
            },
            title: Text(
              receipt['name'] is bool
                  ? AppLocalizations.of(context).notAvailable
                  : receipt['name'],
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF714B67),
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  'Amount: ${receipt['amount']}',
                  style: const TextStyle(fontSize: 14),
                ),
                Text(
                  'Date: ${receipt['date']}',
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getStatusColor(receipt['state']).withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                receipt['state'] ?? '',
                style: TextStyle(
                  color: _getStatusColor(receipt['state']),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Color _getStatusColor(String? state) {
    switch (state?.toLowerCase()) {
      case 'paid':
        return Colors.green;
      case 'draft':
        return Colors.orange;
      case 'in_process':
        return Colors.blue;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

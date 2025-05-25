import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lottie/lottie.dart';
import 'package:odoo/localization.dart';
import 'package:odoo/networking/odoo_service.dart';
import 'cash_receipt_cubit.dart';
import 'cash_receipt_list.dart';

class CashReceiptDetailsPage extends StatelessWidget {
  final int receiptId;

  const CashReceiptDetailsPage({
    Key? key,
    required this.receiptId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => CashReceiptCubit(OdooRpcService())..fetchReceipts(),
      child: WillPopScope(
        onWillPop: () async {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => const CashReceiptListPage(),
            ),
          );
          return false;
        },
        child: Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            iconTheme: const IconThemeData(color: Colors.white),
            title: Text(
              AppLocalizations.of(context).receipt_details,
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
                final receipt = state.receipts.firstWhere(
                  (r) => r['id'] == receiptId,
                  orElse: () => {},
                );
                if (receipt.isEmpty) {
                  return Center(
                    child: Text(AppLocalizations.of(context).no_receipts_found),
                  );
                }
                return _buildReceiptDetails(context, receipt);
              }
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildReceiptDetails(
      BuildContext context, Map<String, dynamic> receipt) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoCard(context, receipt),
          const SizedBox(height: 16),
          if (receipt['state']?.toLowerCase() == 'in_process')
            _buildValidateButton(context),
          if (receipt['state']?.toLowerCase() == 'draft')
            _buildConfermButton(context),
        ],
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, Map<String, dynamic> receipt) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  receipt['name'] is bool
                      ? AppLocalizations.of(context).notAvailable
                      : receipt['name'],
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF714B67),
                      ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
              ],
            ),
            const Divider(height: 24),
            _buildInfoRow(
              Icons.attach_money,
              AppLocalizations.of(context).amount,
              receipt['amount']?.toString() ?? '',
            ),
            _buildInfoRow(
              Icons.calendar_today,
              'Date',
              receipt['date']?.toString() ?? '',
            ),
            if (receipt['partner_id'] != null)
              _buildInfoRow(
                Icons.person,
                'Customer',
                receipt['partner_id'][1]?.toString() ?? '',
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildValidateButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF714B67),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: () async {
          try {
            await context.read<CashReceiptCubit>().validatePayment(receiptId);
            if (context.mounted) {
              // Show success message and navigate back to the list
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(AppLocalizations.of(context).receipt_validated),
                  backgroundColor: Colors.green,
                ),
              );
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => const CashReceiptListPage(),
                ),
              );
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(e.toString()),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
        child: const Text(
          'Validate Receipt',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildConfermButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF714B67),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: () async {
          try {
            await context.read<CashReceiptCubit>().ConfermPayment(receiptId);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(AppLocalizations.of(context).receipt_Confirm),
                  backgroundColor: Colors.green,
                ),
              );
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => const CashReceiptListPage(),
                ),
              );
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(e.toString()),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
        child: const Text(
          'Confirm Receipt',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
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

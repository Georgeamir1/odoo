import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lottie/lottie.dart';

import '../home/home_ui.dart';
import '../localization.dart';
import 'add_stock_picking_line.dart';
import 'stock_picking_request_cubit.dart';
import 'stock_picking_request_details.dart';
import 'stock_picking_request_status.dart';

class StockPickingRequestPage extends StatelessWidget {
  const StockPickingRequestPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          StockPickingRequestCubit()..fetchStockPickingRequests(),
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(70.0),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF714B67),
              borderRadius:
                  const BorderRadius.vertical(bottom: Radius.circular(25)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: AppBar(
              iconTheme: const IconThemeData(color: Colors.white),
              title: Text(
                AppLocalizations.of(context).Transefer_Requests,
                style: const TextStyle(color: Colors.white),
              ),
              backgroundColor: Colors.transparent,
              elevation: 0,
              actions: [
                IconButton(
                  icon: const Icon(Icons.home, color: Colors.white),
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (context) => HomePage(
                          changeLanguage: (String languageCode) {},
                        ),
                      ),
                      (route) => false,
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        body: BlocBuilder<StockPickingRequestCubit, StockPickingRequestState>(
          builder: (context, state) {
            if (state is StockPickingRequestInitial) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is StockPickingRequestLoading) {
              return Center(
                child: Lottie.asset(
                  'assets/images/loading.json',
                  width: 200,
                  height: 200,
                  fit: BoxFit.fill,
                ),
              );
            } else if (state is StockPickingRequestError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error, color: Colors.red, size: 60),
                    const SizedBox(height: 16),
                    Text(
                      state.message,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        context
                            .read<StockPickingRequestCubit>()
                            .fetchStockPickingRequests();
                      },
                      child: Text(AppLocalizations.of(context).tryAgain),
                    ),
                  ],
                ),
              );
            } else if (state is StockPickingRequestLoaded) {
              return Padding(
                padding: const EdgeInsets.only(top: 18.0),
                child: _buildRequestsList(context, state),
              );
            }
            return const Center(child: Text('Unknown state'));
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddStockPickingLine(),
                ));
          },
          backgroundColor: const Color(0xFF714B67),
          child: Text(
            AppLocalizations.of(context).new_order,
            style: TextStyle(color: Colors.white),
          ),
        ),
      ),
    );
  }

  Widget _buildRequestsList(
      BuildContext context, StockPickingRequestLoaded state) {
    if (state.requests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.inventory, color: Colors.grey, size: 60),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context).noStockPickingRequests,
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification scrollInfo) {
        if (scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent &&
            state.hasMore) {
          context.read<StockPickingRequestCubit>().loadMore();
          return true;
        }
        return false;
      },
      child: ListView.builder(
        itemCount: state.requests.length + (state.hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == state.requests.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(8.0),
                child: CircularProgressIndicator(),
              ),
            );
          }

          final request = state.requests[index];
          final requestId = request['id'];
          final requestName = request['name'] ?? 'Unknown';
          final requestState = request['state'] ?? 'draft';
          final scheduledDate = request['create_date'] != null
              ? DateTime.parse(request['create_date'])
              : null;
          final origin = request['warehouse_id'][1] ?? '';

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => StockPickingRequestDetailPage(
                      pickingId: requestId,
                    ),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          requestName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        _buildStatusChip(context, requestState),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (origin != null &&
                        origin != false &&
                        origin.toString().isNotEmpty) ...[
                      Text(
                        '${AppLocalizations.of(context).warehouse}: $origin',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                    ],
                    Text(
                      '${AppLocalizations.of(context).create_date}: ${_formatDate(scheduledDate!)}',
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                    /* const Divider(),
                    Text(
                      '${AppLocalizations.of(context).products}: ${moves.length}',
                      style: const TextStyle(
                        fontSize: 14,
                      ),
                    ),*/
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusChip(BuildContext context, String state) {
    Color chipColor;
    String statusText;

    switch (state) {
      case 'draft':
        chipColor = Colors.grey;
        statusText = AppLocalizations.of(context).draft;
        break;
      case 'waiting':
        chipColor = Colors.orange;
        statusText = AppLocalizations.of(context).waiting;
        break;
      case 'confirmed':
        chipColor = Colors.blue;
        statusText = AppLocalizations.of(context).confirmed;
        break;
      case 'assigned':
        chipColor = Colors.green;
        statusText = AppLocalizations.of(context).ready;
        break;
      case 'done':
        chipColor = Colors.purple;
        statusText = AppLocalizations.of(context).done;
        break;
      case 'cancel':
        chipColor = Colors.red;
        statusText = AppLocalizations.of(context).cancelled;
        break;
      default:
        chipColor = Colors.grey;
        statusText = state;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: chipColor),
      ),
      child: Text(
        statusText,
        style: TextStyle(
          color: chipColor,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

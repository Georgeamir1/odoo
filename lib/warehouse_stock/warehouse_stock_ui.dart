import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:lottie/lottie.dart';
import '../home/home_ui.dart';
import '../localization.dart';
import 'warehouse_stock_cubit.dart';
import 'warehouse_stock_status.dart';

class WarehouseStockPage extends StatelessWidget {
  const WarehouseStockPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => WarehouseStockCubit()..fetchWarehouseStock(),
      child: _WarehouseStockContent(),
    );
  }
}

class _WarehouseStockContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cubit = context.read<WarehouseStockCubit>();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context).warehouse_stock,
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF714B67),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              cubit.fetchWarehouseStock();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(context),
          Expanded(
            child: _buildStockList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return BlocBuilder<WarehouseStockCubit, WarehouseStockState>(
      builder: (context, state) {
        final cubit = context.read<WarehouseStockCubit>();

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            decoration: InputDecoration(
              hintText: AppLocalizations.of(context).search_products,
              prefixIcon: const Icon(Icons.search, color: Color(0xFF714B67)),
              suffixIcon: cubit.searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: Color(0xFF714B67)),
                      onPressed: () {
                        // Clear search and reset
                        cubit.search('');
                      },
                    )
                  : null,
              filled: true,
              fillColor: Colors.grey.shade100,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide:
                    const BorderSide(color: Color(0xFF714B67), width: 1),
              ),
            ),
            onChanged: (value) {
              // Directly call search without debounce to avoid context issues
              cubit.search(value);
            },
          ),
        );
      },
    );
  }

  Widget _buildStockList() {
    return BlocBuilder<WarehouseStockCubit, WarehouseStockState>(
      builder: (context, state) {
        if (state is WarehouseStockLoading) {
          return Center(
            child: Lottie.asset(
              'assets/images/loading3.json',
              width: 200,
              height: 200,
            ),
          );
        } else if (state is WarehouseStockError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  color: Colors.red,
                  size: 60,
                ),
                const SizedBox(height: 16),
                Text(
                  state.message,
                  style: const TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    context.read<WarehouseStockCubit>().fetchWarehouseStock();
                  },
                  child: Text(AppLocalizations.of(context).try_again),
                ),
              ],
            ),
          );
        } else if (state is WarehouseStockLoaded) {
          if (state.stockItems.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    FeatherIcons.package,
                    color: Colors.grey,
                    size: 60,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    AppLocalizations.of(context).no_stock_items_found,
                    style: const TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return NotificationListener<ScrollNotification>(
            onNotification: (ScrollNotification scrollInfo) {
              if (scrollInfo.metrics.pixels ==
                      scrollInfo.metrics.maxScrollExtent &&
                  state.hasMore) {
                context.read<WarehouseStockCubit>().loadMore();
              }
              return true;
            },
            child: ListView.builder(
              itemCount: state.stockItems.length + (state.hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == state.stockItems.length) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                final stockItem = state.stockItems[index];
                final productId = stockItem['product_id'];
                final productName = productId[1] ?? 'Unknown Product';
                final locationId = stockItem['location_id'];
                final locationName = locationId[1] ?? 'Unknown Location';
                final quantity = stockItem['quantity'] ?? 0.0;
                final reservedQuantity = stockItem['reserved_quantity'] ?? 0.0;
                final availableQuantity = quantity - reservedQuantity;

                return Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFF714B67).withAlpha(20),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                FeatherIcons.package,
                                color: Color(0xFF714B67),
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    productName,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(FeatherIcons.mapPin,
                                          size: 14, color: Colors.grey),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          locationName,
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),

                                  // Show lot/serial number if available
                                  if (stockItem['lot_id'] != null &&
                                      stockItem['lot_id'] is List &&
                                      stockItem['lot_id'].length > 1)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Row(
                                        children: [
                                          const Icon(FeatherIcons.hash,
                                              size: 14, color: Colors.grey),
                                          const SizedBox(width: 4),
                                          Text(
                                            "Lot: ${stockItem['lot_id'][1]}",
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Divider(height: 1),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildQuantityInfo(
                              context,
                              AppLocalizations.of(context).on_hand,
                              quantity.toString(),
                              Colors.blue,
                            ),
                            _buildQuantityInfo(
                              context,
                              AppLocalizations.of(context).reserved,
                              reservedQuantity.toString(),
                              Colors.orange,
                            ),
                            _buildQuantityInfo(
                              context,
                              AppLocalizations.of(context).available,
                              availableQuantity.toString(),
                              Colors.green,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildQuantityInfo(
    BuildContext context,
    String label,
    String value,
    Color color,
  ) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withAlpha(25),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}

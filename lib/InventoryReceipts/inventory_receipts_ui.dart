import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lottie/lottie.dart';
import 'package:odoo/InventoryReceipts/widgets.dart';

import '../home/home_ui.dart';
import '../localization.dart';
import 'new_inventory_receipt.dart';
import 'inventory_receipts_cubit.dart';
import 'inventory_receipts_status.dart';

class InventoryReceiptsPage extends StatelessWidget {
  const InventoryReceiptsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => InventoryReceiptsCubit()..fetchInventoryReceiptss(),
      child: BlocConsumer<InventoryReceiptsCubit, InventoryReceiptsState>(
        listener: (context, state) {
          if (state is InventoryReceiptsError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        builder: (context, state) {
          return WillPopScope(
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
              appBar: PreferredSize(
                preferredSize: const Size.fromHeight(70.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Color(0xFF714B67),
                    borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(25),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: AppBar(
                    backgroundColor: Colors.transparent,
                    iconTheme: IconThemeData(color: Colors.white),
                    title: Text(
                      AppLocalizations.of(context).inventoryReceipts,
                      style: TextStyle(color: Colors.white, fontSize: 20),
                    ),
                    actions: [
                      IconButton(
                        icon: const Icon(
                          Icons.search,
                          color: Colors.white,
                        ),
                        onPressed: () => showSearch(
                          context: context,
                          delegate: InventoryReceiptsSearch(
                              InventoryReceiptsCubit.get(context)),
                        ),
                      ),
                      buildFilterMenu(context),
                    ],
                  ),
                ),
              ),
              body: RefreshIndicator(
                onRefresh: () async => InventoryReceiptsCubit.get(context)
                    .fetchInventoryReceiptss(),
                child:
                    BlocBuilder<InventoryReceiptsCubit, InventoryReceiptsState>(
                  builder: (context, state) {
                    if (state is InventoryReceiptsLoading) {
                      return Center(
                          child: Lottie.asset('assets/images/loading3.json',
                              height: 200, width: 200));
                    }
                    if (state is InventoryReceiptsError) {
                      return Center(child: Text(state.message));
                    }
                    if (state is InventoryReceiptsLoaded) {
                      if (state.orders.isEmpty) {
                        return Center(
                            child: Text(
                          AppLocalizations.of(context).no_orders_found,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ));
                      }
                      // Use the buildOrderList function to display the orders.
                      // This function should be defined in your widgets.dart file.
                      // It should take the context, list of orders, and a load more function.
                      return buildOrderList(
                        context,
                        state.orders,
                        () => context.read<InventoryReceiptsCubit>().loadMore(),
                      );
                    }
                    return const Center(child: Text('No orders found'));
                  },
                ),
              ),
              floatingActionButton: FloatingActionButton.extended(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => NewInventoryReceiptsScreen(),
                    ),
                  );
                },
                label: Text(
                  AppLocalizations.of(context).new_order,
                  style: TextStyle(color: Colors.white),
                ),
                backgroundColor: Color(0xFF714B67),
              ),
            ),
          );
        },
      ),
    );
  }
}

class InventoryReceiptsSearch extends SearchDelegate {
  final InventoryReceiptsCubit cubit;

  InventoryReceiptsSearch(this.cubit);

  @override
  List<Widget> buildActions(BuildContext context) => [
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () => query = '',
        )
      ];

  @override
  Widget buildLeading(BuildContext context) => IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => close(context, null),
      );

  @override
  Widget buildResults(BuildContext context) {
    print("Search query: $query"); // Debug log
    // Filter orders based on query.
    cubit.filterOrders(query);

    // Use BlocProvider.value to use the existing cubit instance.
    return BlocProvider.value(
      value: cubit,
      child: BlocConsumer<InventoryReceiptsCubit, InventoryReceiptsState>(
        listener: (context, state) {
          // Optionally handle side-effects.
        },
        builder: (context, state) {
          if (state is InventoryReceiptsLoaded) {
            if (state.orders.isEmpty) {
              return const Center(child: Text("No matching orders found"));
            }
            return ListView.builder(
              itemCount: state.orders.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(state.orders[index]['name']),
                  subtitle: Text(state.orders[index]['origin'].toString()),
                );
              },
            );
          } else if (state is InventoryReceiptsError) {
            return Center(child: Text(state.message));
          }
          return Center(
              child: Lottie.asset('assets/images/loading3.json',
                  height: 10, width: 10));
        },
      ),
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) => buildResults(context);
}

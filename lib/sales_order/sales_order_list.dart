import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lottie/lottie.dart';
import 'package:odoo/sales_order/sales_order_cubit.dart';
import 'package:odoo/sales_order/sales_order_status.dart';
import 'package:odoo/sales_order/new_sales_order.dart';

import '../home/home_ui.dart';
import '../sales_order/widgets.dart';
import '../localization.dart';

class SaleOrderPage extends StatelessWidget {
  const SaleOrderPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SaleOrderCubit()..fetchSaleOrder(),
      child: BlocConsumer<SaleOrderCubit, SaleOrderState>(
        listener: (context, state) {
          if (state is SaleOrderError) {
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
                      AppLocalizations.of(context).order,
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
                          delegate:
                              SaleOrderSearch(SaleOrderCubit.get(context)),
                        ),
                      ),
                      buildFilterMenu(context),
                    ],
                  ),
                ),
              ),
              body: RefreshIndicator(
                onRefresh: () async =>
                    SaleOrderCubit.get(context).fetchSaleOrder(),
                child: BlocBuilder<SaleOrderCubit, SaleOrderState>(
                  builder: (context, state) {
                    if (state is SaleOrderLoading) {
                      return Center(
                          child: Lottie.asset('assets/images/loading3.json',
                              height: 200, width: 200));
                    }
                    if (state is SaleOrderError) {
                      return Center(child: Text(state.message));
                    }
                    if (state is SaleOrderLoaded) {
                      if (state.orders.isEmpty) {
                        return Center(
                            child: Text(
                                AppLocalizations.of(context).no_orders_found,
                                style: TextStyle(fontSize: 18)));
                      }
                      return buildOrderList(
                        context,
                        state.orders,
                        () => context.read<SaleOrderCubit>().loadMore(),
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
                      builder: (context) => QuotationScreen(),
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

class SaleOrderSearch extends SearchDelegate {
  final SaleOrderCubit cubit;

  SaleOrderSearch(this.cubit);

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
      child: BlocConsumer<SaleOrderCubit, SaleOrderState>(
        listener: (context, state) {
          // Optionally handle side-effects.
        },
        builder: (context, state) {
          if (state is SaleOrderLoaded) {
            if (state.orders.isEmpty) {
              return const Center(child: Text("No matching orders found"));
            }
            return ListView.builder(
              itemCount: state.orders.length,
              itemBuilder: (context, index) {
                return ListTile(
                  onTap: () {
                    Navigator.pop(context);
                  },
                  title: Text(state.orders[index]['name']),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(state.orders[index]['partner_id'][1].toString()),
                      Text(state.orders[index]['create_date']),
                    ],
                  ),
                );
              },
            );
          } else if (state is SaleOrderError) {
            return Center(child: Text(state.message));
          }
          return Center(
              child: Lottie.asset('assets/images/loading4.json',
                  height: 10, width: 10));
        },
      ),
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) => buildResults(context);
}

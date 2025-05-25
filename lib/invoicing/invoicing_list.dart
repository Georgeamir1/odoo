import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lottie/lottie.dart';
import 'package:odoo/invoicing/invoicing_cubit.dart';
import 'package:odoo/invoicing/invoicing_status.dart';
import 'package:odoo/sales_order/sales_order_cubit.dart';
import 'package:odoo/sales_order/sales_order_status.dart';
import 'package:odoo/sales_order/new_sales_order.dart';

import '../home/home_ui.dart';
import '../invoicing/widgets.dart';
import '../localization.dart';

class invoicingPage extends StatelessWidget {
  const invoicingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => invoicingCubit()..fetchinvoicing(),
      child: BlocConsumer<invoicingCubit, invoicingState>(
        listener: (context, state) {
          if (state is invoicingError) {
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
                      AppLocalizations.of(context).invoices,
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
                              invoicingSearch(invoicingCubit.get(context)),
                        ),
                      ),
                      buildFilterMenu(context),
                    ],
                  ),
                ),
              ),
              body: RefreshIndicator(
                onRefresh: () async =>
                    invoicingCubit.get(context).fetchinvoicing(),
                child: BlocBuilder<invoicingCubit, invoicingState>(
                  builder: (context, state) {
                    if (state is invoicingLoading) {
                      return Center(
                          child: Lottie.asset('assets/images/loading3.json',
                              height: 200, width: 200));
                    }
                    if (state is invoicingError) {
                      return Center(child: Text(state.message));
                    }
                    if (state is invoicingLoaded) {
                      return Stack(
                        alignment: Alignment
                            .bottomRight, // Positions the FAB in the bottom right.
                        children: [
                          // Your list widget should expand as needed.
                          buildOrderList(
                            context,
                            state.orders,
                            () => context.read<invoicingCubit>().loadMore(),
                          ),
                          if (state.orders.length <
                              context
                                  .read<invoicingCubit>()
                                  .filteredOrders
                                  .length)
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  FloatingActionButton.extended(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              QuotationScreen(),
                                        ),
                                      );
                                    },
                                    label: Text(
                                      AppLocalizations.of(context).new_order,
                                      style: TextStyle(color: Colors.white),
                                    ),
                                    backgroundColor: Color(0xFF714B67),
                                  ),
                                  /*  FloatingActionButton.extended(
                                    onPressed: () =>
                                        context.read<invoicingCubit>().loadMore(),
                                    label: Text(
                                      AppLocalizations.of(context).load_more,
                                      style: TextStyle(color: Colors.white),
                                    ),
                                    backgroundColor: Color(0xFF714B67),
                                  ),*/
                                ],
                              ),
                            ),
                        ],
                      );
                    }
                    return const Center(child: Text('No orders found'));
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class invoicingSearch extends SearchDelegate {
  final invoicingCubit cubit;

  invoicingSearch(this.cubit);

  @override
  ThemeData appBarTheme(BuildContext context) {
    return Theme.of(context).copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: Color(0xFF714B67),
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        hintStyle: TextStyle(color: Colors.white70),
        border: InputBorder.none,
      ),
    );
  }

  @override
  List<Widget> buildActions(BuildContext context) => [
        IconButton(
          icon: const Icon(Icons.clear, color: Colors.white),
          onPressed: () {
            if (query.isEmpty) {
              close(context, null);
            } else {
              query = '';
            }
          },
        )
      ];

  @override
  Widget buildLeading(BuildContext context) => IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => close(context, null),
      );

  @override
  Widget buildResults(BuildContext context) {
    if (query.isEmpty) {
      return buildSuggestions(context);
    }

    cubit.filterOrders(query);

    return BlocProvider.value(
      value: cubit,
      child: BlocConsumer<invoicingCubit, invoicingState>(
        listener: (context, state) {},
        builder: (context, state) {
          if (state is invoicingLoading) {
            return Center(
              child: Lottie.asset('assets/images/loading3.json',
                  height: 100, width: 100),
            );
          }

          if (state is invoicingLoaded) {
            if (state.orders.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.search_off, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      "No matching invoices found",
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              itemCount: state.orders.length,
              itemBuilder: (context, index) {
                final order = state.orders[index];
                return Card(
                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  elevation: 2,
                  child: ListTile(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    title: Text(
                      order['name'] ?? 'N/A',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 4),
                        Text(
                          order['partner_id'] == false
                              ? 'Customer: N/A'
                              : 'Customer: ${order['partner_id'][1]}',
                          style: TextStyle(color: Colors.grey[700]),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Date: ${order['create_date']}',
                          style: TextStyle(color: Colors.grey[700]),
                        ),
                        if (order['amount_total'] != null)
                          Text(
                            'Amount: ${order['amount_total'].toStringAsFixed(2)}',
                            style: TextStyle(
                              color: Color(0xFF714B67),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                      ],
                    ),
                    trailing: Icon(Icons.chevron_right),
                  ),
                );
              },
            );
          }

          if (state is invoicingError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red),
                  SizedBox(height: 16),
                  Text(
                    state.message,
                    style: TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              "Search by invoice number, customer name, or date",
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return buildResults(context);
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lottie/lottie.dart';
import 'package:odoo/delivery_order/delivery_order_widgets.dart';
import '../localization.dart';
import 'delivery_order_cubit.dart';
import 'delivery_order_status.dart';
import '../InventoryReceipts/new_inventory_receipt.dart';
import 'new_delivery_order.dart';

class DeliveryOrderPage extends StatelessWidget {
  const DeliveryOrderPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => DeliveryOrderCubit()..fetchDeliveryOrders(),
      child: BlocConsumer<DeliveryOrderCubit, DeliveryOrderState>(
        listener: (context, state) {
          if (state is DeliveryOrderError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        builder: (context, state) {
          return Scaffold(
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
                  title: Text(AppLocalizations.of(context).delivery_orders,
                      style: TextStyle(color: Colors.white)),
                  actions: [
                    IconButton(
                      icon: Icon(Icons.search, color: Colors.white),
                      onPressed: () => showSearch(
                        context: context,
                        delegate: DeliveryOrderSearch(
                            DeliveryOrderCubit.get(context)),
                      ),
                    ),
                    buildFilterMenu(context),
                  ],
                ),
              ),
            ),
            body: RefreshIndicator(
              onRefresh: () async =>
                  DeliveryOrderCubit.get(context).fetchDeliveryOrders(),
              child: BlocBuilder<DeliveryOrderCubit, DeliveryOrderState>(
                builder: (context, state) {
                  if (state is DeliveryOrderLoading) {
                    return Center(
                        child: Lottie.asset('assets/images/loading4.json',
                            height: 200, width: 200));
                  }
                  if (state is DeliveryOrderError) {
                    return Center(child: Text(state.message));
                  }
                  if (state is DeliveryOrderLoaded) {
                    return Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        buildOrderList(
                          context,
                          state.orders,
                          () => context.read<DeliveryOrderCubit>().loadMore(),
                        ),
                        if (state.orders.length <
                            context.read<DeliveryOrderCubit>().allOrders.length)
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                FloatingActionButton.extended(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            newdeliveryorderScreen(),
                                      ),
                                    );
                                  },
                                  label: Text(
                                      AppLocalizations.of(context).new_order,
                                      style: TextStyle(color: Colors.white)),
                                  tooltip: "Load more orders",
                                  backgroundColor: Color(0xFF714B67),
                                ),
                                /*     FloatingActionButton.extended(
                                  onPressed: () => context
                                      .read<DeliveryOrderCubit>()
                                      .loadMore(),
                                  label: Text(
                                      AppLocalizations.of(context).load_more,
                                      style: TextStyle(color: Colors.white)),
                                  tooltip: "Load more orders",
                                  backgroundColor: Color(0xFF714B67),
                                ),*/
                              ],
                            ),
                          ),
                      ],
                    );
                  }
                  return Center(
                      child:
                          Text(AppLocalizations.of(context).no_orders_found));
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

class DeliveryOrderSearch extends SearchDelegate {
  final DeliveryOrderCubit cubit;

  DeliveryOrderSearch(this.cubit);

  @override
  List<Widget> buildActions(BuildContext context) => [
        IconButton(
          icon: Icon(Icons.clear),
          onPressed: () => query = '',
          tooltip: AppLocalizations.of(context).clear,
        )
      ];

  @override
  Widget buildLeading(BuildContext context) => IconButton(
        icon: Icon(Icons.arrow_back),
        onPressed: () => close(context, null),
        tooltip: AppLocalizations.of(context).back,
      );

  @override
  Widget buildResults(BuildContext context) {
    cubit.filterOrders(query);

    return BlocProvider.value(
      value: cubit,
      child: BlocConsumer<DeliveryOrderCubit, DeliveryOrderState>(
        listener: (context, state) {},
        builder: (context, state) {
          if (state is DeliveryOrderLoaded) {
            if (state.orders.isEmpty) {
              return Center(
                  child: Text(
                      AppLocalizations.of(context).no_matching_orders_found));
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
          } else if (state is DeliveryOrderError) {
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

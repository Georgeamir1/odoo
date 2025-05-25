import 'package:equatable/equatable.dart';

abstract class WarehouseStockState extends Equatable {
  const WarehouseStockState();

  @override
  List<Object?> get props => [];
}

// Initial state
class WarehouseStockInitial extends WarehouseStockState {}

// Loading state
class WarehouseStockLoading extends WarehouseStockState {}

// Loaded state with stock data
class WarehouseStockLoaded extends WarehouseStockState {
  final List<Map<String, dynamic>> stockItems;
  final bool hasMore;

  const WarehouseStockLoaded(this.stockItems, {this.hasMore = false});

  @override
  List<Object?> get props => [stockItems, hasMore];
}

// Error state
class WarehouseStockError extends WarehouseStockState {
  final String message;

  const WarehouseStockError(this.message);

  @override
  List<Object?> get props => [message];
}

// Detail loading state
class WarehouseStockDetailLoading extends WarehouseStockState {}

// Detail loaded state
class WarehouseStockDetailLoaded extends WarehouseStockState {
  final Map<String, dynamic> stockDetail;

  const WarehouseStockDetailLoaded(this.stockDetail);

  @override
  List<Object?> get props => [stockDetail];
}

// Detail error state
class WarehouseStockDetailError extends WarehouseStockState {
  final String message;

  const WarehouseStockDetailError(this.message);

  @override
  List<Object?> get props => [message];
}

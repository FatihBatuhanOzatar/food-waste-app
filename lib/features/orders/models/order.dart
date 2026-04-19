import 'package:equatable/equatable.dart';

import 'order_status.dart';

/// A user reservation/order for a surplus food product.
///
/// Maps to the `orders` table in Supabase. Includes denormalized
/// product and business names from JOINs for display purposes.
class Order extends Equatable {
  /// Creates an [Order] with the given fields.
  const Order({
    required this.id,
    required this.userId,
    required this.productId,
    required this.businessId,
    required this.pricePaid,
    required this.originalPrice,
    required this.status,
    required this.createdAt,
    this.cancelledReason,
    this.confirmedAt,
    this.pickedUpAt,
    this.cancelledAt,
    this.productName,
    this.productImageUrl,
    this.businessName,
  });

  /// Creates an [Order] from a Supabase JSON response.
  ///
  /// Expects optional nested `products(name, image_url)` and
  /// `businesses(name)` from JOINs.
  factory Order.fromJson(Map<String, dynamic> json) {
    final product = json['products'] as Map<String, dynamic>?;
    final business = json['businesses'] as Map<String, dynamic>?;

    return Order(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      productId: json['product_id'] as String,
      businessId: json['business_id'] as String,
      pricePaid: (json['price_paid'] as num).toDouble(),
      originalPrice: (json['original_price'] as num).toDouble(),
      status: OrderStatus.fromString(json['status'] as String? ?? 'pending'),
      cancelledReason: json['cancelled_reason'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      confirmedAt: json['confirmed_at'] != null
          ? DateTime.parse(json['confirmed_at'] as String)
          : null,
      pickedUpAt: json['picked_up_at'] != null
          ? DateTime.parse(json['picked_up_at'] as String)
          : null,
      cancelledAt: json['cancelled_at'] != null
          ? DateTime.parse(json['cancelled_at'] as String)
          : null,
      productName: product?['name'] as String?,
      productImageUrl: product?['image_url'] as String?,
      businessName: business?['name'] as String?,
    );
  }

  /// Unique order identifier.
  final String id;

  /// The user who placed this reservation.
  final String userId;

  /// The product being reserved.
  final String productId;

  /// The business that listed the product.
  final String businessId;

  /// Price the user will pay at pickup.
  final double pricePaid;

  /// Original price before discount (frozen at order time).
  final double originalPrice;

  /// Current order status.
  final OrderStatus status;

  /// Reason for cancellation (nullable).
  final String? cancelledReason;

  /// When the order was created.
  final DateTime createdAt;

  /// When the business confirmed the order.
  final DateTime? confirmedAt;

  /// When the user picked up the product.
  final DateTime? pickedUpAt;

  /// When the order was cancelled.
  final DateTime? cancelledAt;

  // --- Denormalized fields from JOINs ---

  /// Product name (from JOIN).
  final String? productName;

  /// Product image URL (from JOIN).
  final String? productImageUrl;

  /// Business name (from JOIN).
  final String? businessName;

  /// Money saved compared to original price.
  double get savings => originalPrice - pricePaid;

  /// Whether the order can be cancelled by the user.
  bool get isCancellable =>
      status == OrderStatus.pending || status == OrderStatus.confirmed;

  /// Serializes this [Order] to a JSON map for Supabase insert.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'product_id': productId,
      'business_id': businessId,
      'price_paid': pricePaid,
      'original_price': originalPrice,
      'status': status.dbValue,
      'cancelled_reason': cancelledReason,
      'created_at': createdAt.toIso8601String(),
      'confirmed_at': confirmedAt?.toIso8601String(),
      'picked_up_at': pickedUpAt?.toIso8601String(),
      'cancelled_at': cancelledAt?.toIso8601String(),
    };
  }

  /// Creates a copy of this [Order] with the given fields replaced.
  Order copyWith({
    String? id,
    String? userId,
    String? productId,
    String? businessId,
    double? pricePaid,
    double? originalPrice,
    OrderStatus? status,
    String? cancelledReason,
    DateTime? createdAt,
    DateTime? confirmedAt,
    DateTime? pickedUpAt,
    DateTime? cancelledAt,
    String? productName,
    String? productImageUrl,
    String? businessName,
  }) {
    return Order(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      productId: productId ?? this.productId,
      businessId: businessId ?? this.businessId,
      pricePaid: pricePaid ?? this.pricePaid,
      originalPrice: originalPrice ?? this.originalPrice,
      status: status ?? this.status,
      cancelledReason: cancelledReason ?? this.cancelledReason,
      createdAt: createdAt ?? this.createdAt,
      confirmedAt: confirmedAt ?? this.confirmedAt,
      pickedUpAt: pickedUpAt ?? this.pickedUpAt,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      productName: productName ?? this.productName,
      productImageUrl: productImageUrl ?? this.productImageUrl,
      businessName: businessName ?? this.businessName,
    );
  }

  @override
  List<Object?> get props => [
    id,
    userId,
    productId,
    businessId,
    pricePaid,
    originalPrice,
    status,
    cancelledReason,
    createdAt,
    confirmedAt,
    pickedUpAt,
    cancelledAt,
    productName,
    productImageUrl,
    businessName,
  ];
}

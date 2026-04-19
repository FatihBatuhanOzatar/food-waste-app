import 'package:equatable/equatable.dart';

/// A surplus food product listed by a business on the marketplace.
///
/// Represents both regular menu items (`listing_type == 'menu_item'`)
/// and surprise boxes (`listing_type == 'surprise_box'`).
///
/// The query JOINs with the `businesses` table to embed the business
/// name and location inside the product row.
class Product extends Equatable {
  /// Creates a [Product] with the given fields.
  const Product({
    required this.id,
    required this.businessId,
    required this.name,
    required this.category,
    required this.listingType,
    required this.originalPrice,
    required this.currentPrice,
    required this.stock,
    required this.pickupStart,
    required this.pickupEnd,
    required this.status,
    required this.createdAt,
    this.description,
    this.imageUrl,
    this.businessName,
    this.businessLatitude,
    this.businessLongitude,
  });

  /// Creates a [Product] from a Supabase JSON response.
  ///
  /// Expects the query to include `businesses(name, latitude, longitude)`
  /// so that the nested `businesses` object is present.
  factory Product.fromJson(Map<String, dynamic> json) {
    // Extract nested business data from the JOIN.
    final business = json['businesses'] as Map<String, dynamic>?;

    return Product(
      id: json['id'] as String,
      businessId: json['business_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      imageUrl: json['image_url'] as String?,
      category: json['category'] as String,
      listingType: json['listing_type'] as String,
      originalPrice: (json['original_price'] as num).toDouble(),
      currentPrice: (json['current_price'] as num).toDouble(),
      stock: json['stock'] as int? ?? 0,
      pickupStart: DateTime.parse(json['pickup_start'] as String),
      pickupEnd: DateTime.parse(json['pickup_end'] as String),
      status: json['status'] as String? ?? 'active',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      businessName: business?['name'] as String?,
      businessLatitude: business?['latitude'] != null
          ? (business!['latitude'] as num).toDouble()
          : null,
      businessLongitude: business?['longitude'] != null
          ? (business!['longitude'] as num).toDouble()
          : null,
    );
  }

  /// Unique product identifier.
  final String id;

  /// The business that listed this product.
  final String businessId;

  /// Product display name.
  final String name;

  /// Optional description of the product contents.
  final String? description;

  /// URL to the product image (nullable — no images in MVP).
  final String? imageUrl;

  /// Product category: bread, pastry, sandwich, dessert, drink, mixed_box, other.
  final String category;

  /// Listing type: `menu_item` or `surprise_box`.
  final String listingType;

  /// Original full price before discount.
  final double originalPrice;

  /// Current discounted price.
  final double currentPrice;

  /// Available stock count.
  final int stock;

  /// Start of the pickup window.
  final DateTime pickupStart;

  /// End of the pickup window.
  final DateTime pickupEnd;

  /// Product status: active, sold_out, expired, cancelled.
  final String status;

  /// When the listing was created.
  final DateTime createdAt;

  // --- Denormalized fields from the businesses JOIN ---

  /// Business display name (from JOIN).
  final String? businessName;

  /// Business latitude (from JOIN).
  final double? businessLatitude;

  /// Business longitude (from JOIN).
  final double? businessLongitude;

  /// Whether this is a surprise box listing.
  bool get isSurpriseBox => listingType == 'surprise_box';

  /// Whether the product is currently active and orderable.
  bool get isActive => status == 'active' && stock > 0;

  /// Discount percentage relative to original price.
  int get discountPercent {
    if (originalPrice <= 0) return 0;
    return ((1 - currentPrice / originalPrice) * 100).round();
  }

  /// Remaining time until pickup window ends.
  Duration get remainingTime {
    final now = DateTime.now();
    final diff = pickupEnd.difference(now);
    return diff.isNegative ? Duration.zero : diff;
  }

  /// Whether the pickup window has expired.
  bool get isExpired => remainingTime == Duration.zero;

  /// Serializes this [Product] to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'business_id': businessId,
      'name': name,
      'description': description,
      'image_url': imageUrl,
      'category': category,
      'listing_type': listingType,
      'original_price': originalPrice,
      'current_price': currentPrice,
      'stock': stock,
      'pickup_start': pickupStart.toIso8601String(),
      'pickup_end': pickupEnd.toIso8601String(),
      'status': status,
      'created_at': createdAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
    id,
    businessId,
    name,
    description,
    imageUrl,
    category,
    listingType,
    originalPrice,
    currentPrice,
    stock,
    pickupStart,
    pickupEnd,
    status,
    createdAt,
    businessName,
    businessLatitude,
    businessLongitude,
  ];
}

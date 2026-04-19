import 'package:equatable/equatable.dart';

/// A business entity (bakery, café, patisserie) on the marketplace.
///
/// Maps to the `businesses` table in Supabase. Each business belongs
/// to a single owner (profile with `role == 'business'`).
class Business extends Equatable {
  /// Creates a [Business] with the given fields.
  const Business({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.category,
    required this.isActive,
    required this.createdAt,
    this.description,
    this.phone,
    this.logoUrl,
  });

  /// Creates a [Business] from a Supabase `businesses` table JSON response.
  factory Business.fromJson(Map<String, dynamic> json) {
    return Business(
      id: json['id'] as String,
      ownerId: json['owner_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      phone: json['phone'] as String?,
      address: json['address'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      logoUrl: json['logo_url'] as String?,
      category: json['category'] as String,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  /// Unique business identifier.
  final String id;

  /// Owner profile ID (references `profiles.id`).
  final String ownerId;

  /// Business display name.
  final String name;

  /// Optional description of the business.
  final String? description;

  /// Business phone number.
  final String? phone;

  /// Physical address of the business.
  final String address;

  /// Latitude coordinate for map display.
  final double latitude;

  /// Longitude coordinate for map display.
  final double longitude;

  /// URL to the business logo image (nullable).
  final String? logoUrl;

  /// Business category: bakery, cafe, patisserie, other.
  final String category;

  /// Whether the business is currently active and visible.
  final bool isActive;

  /// When the business was created.
  final DateTime createdAt;

  /// Serializes this [Business] to a JSON map for Supabase insert/update.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'owner_id': ownerId,
      'name': name,
      'description': description,
      'phone': phone,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'logo_url': logoUrl,
      'category': category,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Creates a copy of this [Business] with the given fields replaced.
  Business copyWith({
    String? id,
    String? ownerId,
    String? name,
    String? description,
    String? phone,
    String? address,
    double? latitude,
    double? longitude,
    String? logoUrl,
    String? category,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return Business(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      name: name ?? this.name,
      description: description ?? this.description,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      logoUrl: logoUrl ?? this.logoUrl,
      category: category ?? this.category,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    ownerId,
    name,
    description,
    phone,
    address,
    latitude,
    longitude,
    logoUrl,
    category,
    isActive,
    createdAt,
  ];
}

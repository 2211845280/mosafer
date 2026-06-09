class HomeAddress {
  final String? address;
  final double? lat;
  final double? lng;
  final bool useManualOrigin;

  const HomeAddress({
    this.address,
    this.lat,
    this.lng,
    this.useManualOrigin = false,
  });

  bool get hasCoordinates => lat != null && lng != null;

  bool get isUsableManualOrigin => useManualOrigin && hasCoordinates;

  HomeAddress copyWith({
    String? address,
    double? lat,
    double? lng,
    bool? useManualOrigin,
  }) {
    return HomeAddress(
      address: address ?? this.address,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      useManualOrigin: useManualOrigin ?? this.useManualOrigin,
    );
  }

  static HomeAddress fromJson(Map<String, dynamic> json) {
    return HomeAddress(
      address: json['home_address'] as String?,
      lat: (json['home_lat'] as num?)?.toDouble(),
      lng: (json['home_lng'] as num?)?.toDouble(),
    );
  }
}

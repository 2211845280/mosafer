String? timelineHeroAssetForDestination(String? iata) {
  return switch (iata?.toUpperCase()) {
    'MJI' => 'assets/images/timeline/mitiga.jpeg',
    'CAI' => 'assets/images/timeline/cairo.jpg',
    'IST' || 'SAW' => 'assets/images/timeline/istanbul.jpg',
    'DXB' => 'assets/images/timeline/dubai.jpg',
    _ => null,
  };
}

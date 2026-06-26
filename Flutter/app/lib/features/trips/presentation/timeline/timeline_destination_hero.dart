String? timelineHeroAssetForDestination(String? iata) {
  return switch (iata?.toUpperCase()) {
    'MJI' => 'assets/images/timeline/mitiga.jpeg',
    'CAI' => 'assets/images/timeline/cairo.jpg',
    'IST' || 'SAW' => 'assets/images/timeline/istanbul.jpg',
    'DXB' => 'assets/images/timeline/dubai.jpg',
    'LHR' || 'LGW' || 'STN' || 'LTN' => 'assets/images/timeline/london.jpg',
    'CDG' || 'ORY' => 'assets/images/timeline/paris.jpg',
    'JFK' || 'EWR' || 'LGA' => 'assets/images/timeline/new_york.jpg',
    _ => null,
  };
}

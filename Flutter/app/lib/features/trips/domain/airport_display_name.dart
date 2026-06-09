import 'package:flutter/material.dart';

const _arabicAirportNames = <String, String>{
  'AMM': 'مطار الملكة علياء الدولي',
  'CAI': 'مطار القاهرة الدولي',
  'DXB': 'مطار دبي الدولي',
  'IST': 'مطار إسطنبول',
  'JFK': 'مطار جون ف. كينيدي الدولي',
  'LHR': 'مطار هيثرو',
  'MJI': 'مطار معيتيقة',
};

String airportDisplayName({
  required String iata,
  required String englishName,
  required Locale locale,
}) {
  if (locale.languageCode != 'ar') {
    return englishName;
  }

  final code = iata.trim().toUpperCase();
  return _arabicAirportNames[code] ?? englishName;
}

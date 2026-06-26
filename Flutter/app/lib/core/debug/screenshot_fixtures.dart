import '../../features/profile/presentation/profile_state.dart';
import '../../features/trips/domain/ai_travel.dart';
import '../../features/trips/domain/trip.dart';

const kScreenshotProfile = ProfileState(
  fullName: 'abdo',
  email: 'abdo@gmail.com',
  phoneNumber: '09111111111',
  location: 'طرابلس، ليبيا',
);

Trip get kScreenshotMockTrip => Trip(
      reservationId: 3,
      airline: 'TK 691',
      imageLabel: 'TK',
      fromCode: 'IST',
      fromCity: 'إسطنبول',
      toCode: 'LHR',
      toCity: 'لندن',
      dateTime: '22 يوليو 2026 • 09:15',
      seat: '24C',
      status: TripStatus.confirmed,
      departureAt: DateTime(2026, 7, 22, 9, 15),
      arrivalAt: DateTime(2026, 7, 22, 11, 40),
      flightNumber: '691',
    );

List<Trip> get kScreenshotMockTrips => [
      kScreenshotMockTrip,
      Trip(
        reservationId: 2,
        airline: 'MS 804',
        imageLabel: 'MS',
        fromCode: 'MJI',
        fromCity: 'طرابلس',
        toCode: 'CAI',
        toCity: 'القاهرة',
        dateTime: '15 يونيو 2026 • 14:30',
        seat: '12A',
        status: TripStatus.confirmed,
        departureAt: DateTime(2026, 6, 15, 14, 30),
        arrivalAt: DateTime(2026, 6, 15, 19, 45),
        flightNumber: '804',
      ),
    ];

Map<String, dynamic> get kScreenshotHomePreferences => const {
      'home_address': 'طرابلس، ليبيا',
      'home_lat': 32.8872,
      'home_lng': 13.1913,
    };

PackingListResult get kScreenshotPackingList => PackingListResult.fromJson({
      'must_have': [
        {
          'key': 'passport',
          'title': 'جواز السفر',
          'title_ar': 'جواز السفر',
          'title_en': 'Passport',
          'note_ar': 'وثيقة أساسية للسفر الدولي.',
          'note_en': 'Essential document for international travel.',
        },
        {
          'key': 'entry_visa',
          'title': 'تأشيرة الدخول',
          'title_ar': 'تأشيرة الدخول',
          'title_en': 'Entry visa',
          'note_ar': 'إذا كانت مطلوبة حسب جنسية المسافر.',
          'note_en': 'If required based on traveler nationality.',
        },
      ],
      'recommended': [
        {
          'key': 'summer_clothes',
          'title': 'ملابس صيفية',
          'title_ar': 'ملابس صيفية',
          'title_en': 'Summer clothes',
          'note_ar': 'مثل القمصان الخفيفة والسراويل القصيرة.',
          'note_en': 'Like light shirts and shorts.',
        },
        {
          'key': 'small_backpack',
          'title': 'حقيبة ظهر صغيرة',
          'title_ar': 'حقيبة ظهر صغيرة',
          'title_en': 'Small backpack',
          'note_ar': 'للتنقل السهل خلال الرحلة.',
          'note_en': 'For easy movement during the trip.',
        },
        {
          'key': 'umbrella',
          'title': 'مظلة صغيرة',
          'title_ar': 'مظلة صغيرة',
          'title_en': 'Small umbrella',
          'note_ar': 'للحماية من الأمطار المفاجئة.',
          'note_en': 'For protection from sudden rain.',
        },
      ],
      'weather': {
        'destination_city': 'London',
        'trip_duration_days': 5,
        'condition': 'cloudy',
        'temperature_c': 19,
      },
    });

TimelineResult get kScreenshotTimeline => TimelineResult.fromJson({
      'items': [
        {
          'days_before': 14,
          'title': 'Check passport validity',
          'description':
              'تأكد من أن جواز سفرك ساري المفعول ومناسب للسفر إلى المملكة المتحدة.',
          'category': 'documents',
        },
        {
          'days_before': 14,
          'title': 'Apply for entry visa',
          'description':
              'تحقق مما إذا كنت بحاجة إلى تأشيرة للدخول إلى المملكة المتحدة وقم بالتقديم إذا لزم الأمر.',
          'category': 'documents',
        },
        {
          'days_before': 14,
          'title': 'Check passport validity',
          'description': 'تأكد من صلاحية 6 أشهر على الأقل',
          'category': 'documents',
        },
        {
          'days_before': 7,
          'title': 'Check visa and travel documents',
          'description': 'راجع نسخ التأشيرة والوثائق المطلوبة قبل السفر.',
          'category': 'documents',
        },
      ],
    });

List<Map<String, dynamic>> get kScreenshotTodos => [
      {
        'id': 1,
        'title': 'بطاقة الهوية',
        'title_ar': 'بطاقة الهوية',
        'title_en': 'ID card',
        'category': 'packing',
        'source': 'packing',
        'source_key': 'id_card',
        'is_completed': false,
      },
      {
        'id': 2,
        'title': 'شاحن الهاتف',
        'title_ar': 'شاحن الهاتف',
        'title_en': 'Phone charger',
        'category': 'packing',
        'source': 'packing',
        'source_key': 'phone_charger',
        'is_completed': false,
      },
      {
        'id': 3,
        'title': 'محول طاقة بريطاني',
        'title_ar': 'محول طاقة بريطاني',
        'title_en': 'UK power adapter',
        'category': 'packing',
        'source': 'packing',
        'source_key': 'uk_power_adapter',
        'is_completed': false,
      },
    ];

List<Map<String, dynamic>> get kScreenshotNotifications => [
      {
        'id': 1,
        'type': 'trip',
        'title': 'تم الدفع بنجاح',
        'body': 'تمت معالجة دفعتك بمبلغ 420.00 USD.',
        'read': false,
        'created_at': DateTime.now()
            .subtract(const Duration(days: 1))
            .toIso8601String(),
      },
      {
        'id': 2,
        'type': 'trip',
        'title': 'تم الدفع بنجاح',
        'body': 'تمت معالجة دفعتك بمبلغ 1020.00 USD.',
        'read': false,
        'created_at': DateTime.now()
            .subtract(const Duration(days: 1))
            .toIso8601String(),
      },
      {
        'id': 3,
        'type': 'trip',
        'title': 'تم استرداد الدفع',
        'body': 'تم استرداد 408.00 USD إلى حسابك.',
        'read': false,
        'created_at': DateTime.now()
            .subtract(const Duration(days: 1))
            .toIso8601String(),
      },
      {
        'id': 4,
        'type': 'trip',
        'title': 'تم الدفع بنجاح',
        'body': 'تمت معالجة دفعتك بمبلغ 408.00 USD.',
        'read': false,
        'created_at': DateTime.now()
            .subtract(const Duration(days: 1))
            .toIso8601String(),
      },
    ];

Map<String, dynamic> get kScreenshotDeparturePlan => {
      'distance_km': 9.0,
      'travel_minutes': 10,
      'traffic_level': 'light',
      'leave_at': DateTime(2026, 7, 22, 7, 45).toIso8601String(),
      'origin_lat': 32.8872,
      'origin_lng': 13.1913,
      'airport_lat': 32.8941,
      'airport_lng': 13.2760,
      'encoded_polyline': '_p~iF~ps|U_ulLnnqC_mqNvxq`@',
      'weather': {
        'condition': 'clear',
        'temperature_c': 28,
        'description': 'Clear',
      },
      'destination_weather': {
        'condition': 'cloudy',
        'temperature_c': 19,
        'description': 'Cloudy',
      },
      'weather_buffer_minutes': 0,
    };

Map<String, dynamic> get kScreenshotAirportDashboard => {
      'gate': 'G12',
      'terminal': 'Main',
      'level': '1',
      'boarding_status': 'on_time',
      'security_wait_minutes': 12,
      'walk_minutes_to_gate': 8,
      'flight_status': 'on_time',
    };

List<Map<String, dynamic>> get kScreenshotTickets => [
      {
        'booking_id': 3,
        'ticket_number': 'TK-691-24C-DOC',
        'passenger_name': 'abdo',
        'from_code': 'IST',
        'to_code': 'LHR',
      },
    ];

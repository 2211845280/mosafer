/// Updated when the user changes app language so [ApiClient] can send
/// [Accept-Language] without holding a [Ref].
class AcceptLanguageHolder {
  AcceptLanguageHolder._();

  static String value = 'en';
}

# لقطات واجهات مسافر

مجلد يحتوي لقطات ملونة لجميع شاشات التطبيق داخل **إطار هاتف أندرويد** لاستخدامها في التوثيق.

## الملفات

| المسار | الوصف |
|--------|--------|
| `android/*.png` | الصور النهائية داخل إطار أندرويد (22 شاشة) |
| `previews/*.png` | نسخ أصغر للمعاينة السريعة في المحرر |
| `raw/*.png` | اللقطات الخام قبل الإطار |
| `../app-ui-gallery.html` | معرض تفاعلي لكل الشاشات |
| `../app-ui-screens.md` | فهرس Markdown جاهز للتوثيق |

## إعادة التوليد

1. شغّل الـ backend (`docker compose up`).
2. في نافذتين منفصلتين داخل `Flutter/app`:

```bash
# تطبيق عادي (شاشات الدخول) — عربي للتوثيق
flutter run -d web-server --web-port=7357 --web-hostname=127.0.0.1 --dart-define=DOC_CAPTURE_LOCALE=ar

# وضع لقطات الشاشات (بيانات تجريبية) — عربي
flutter run -d web-server --web-port=7358 --web-hostname=127.0.0.1 --dart-define=SCREENSHOT_MODE=true --dart-define=DOC_CAPTURE_LOCALE=ar
```

إذا كانت المنافذ مشغولة، استخدم منافذ بديلة (مثل 7359 و 7362) واضبط المتغيرات قبل تشغيل السكربت:

```bash
# PowerShell
$env:SCREENSHOT_AUTH_URL="http://127.0.0.1:7359"
$env:SCREENSHOT_APP_URL="http://127.0.0.1:7362"
python scripts/capture_ui_screenshots.py
```

3. من جذر المستودع:

```bash
python scripts/capture_ui_screenshots.py
```

## قائمة الشاشات

1. تسجيل الدخول — 2. إنشاء حساب — 3. نسيت كلمة المرور — 4. إعادة تعيين كلمة المرور
5. الرحلات — 6. رحلاتي — 7. الحساب — 8. الإعدادات
9. في المنزل — 10. في الطريق — 11. في المطار
12. خطة المغادرة — 13. قائمة التجهيز — 14. الجدول الزمني — 15. قائمة المهام
16. مسح التذكرة — 17. الإشعارات — 18. تفاصيل التذكرة
19. تعديل الملف — 20. تغيير كلمة المرور — 21. سلة المحذوفات — 22. خريطة المطار

## عرض الصور

- **الأفضل:** افتح `docs/app-ui-gallery.html` في المتصفح (Chrome / Edge).
- **من Markdown:** افتح `docs/app-ui-screens.md` ثم اضغط معاينة Markdown (Ctrl+Shift+V).
- **إذا فشلت معاينة PNG في Cursor:** جرّب `previews/` أو افتح الملف من مستكشف Windows (Photos).
- **OneDrive:** تأكد أن الملفات «متوفرة دائماً على هذا الجهاز» وليست سحابية فقط.

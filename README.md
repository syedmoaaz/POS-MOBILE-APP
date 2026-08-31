# Shop POS

Flutter Android POS: inventory, barcode, customers, thermal print, 30-day trial.

## Complete (shop APK)

- Login (demo ID/password — Supabase admin baad mein)
- POS cart, typed items, barcode camera/webcam
- Inventory save (SQLite)
- Cash / Card / Udhaar, change, bill discount
- Hold / recall bill
- Customers + credit
- Reports / Z-report, reprint, return
- Shop header settings
- 80mm ESC/POS print (Bluetooth on **phone**; Chrome = preview)
- 30-day license from first login

Not in this APK yet: cloud sync, your admin website, Play Store.

## Chrome

```bat
cd /d D:\Projects\pos-app
set PATH=C:\Users\PC\flutter\bin;%PATH%
flutter run -d chrome
```

## APK (phone testing)

Install Android Studio + SDK, USB debugging, then:

```bat
cd /d D:\Projects\pos-app
set PATH=C:\Users\PC\flutter\bin;%PATH%
flutter build apk --debug
```

APK: `build\app\outputs\flutter-apk\app-debug.apk`

Printer: Android Bluetooth settings se Speed-X pair (PIN 0000/1234), phir app Settings → Choose bonded printer.

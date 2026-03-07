# CatFoodCheck App

CatFoodCheck App is a Flutter mobile application that allows users to scan cat food barcodes and quickly check whether the product's brand complies with the WSAVA (World Small Animal Veterinary Association) guidelines.

The app connects to the CatFoodCheck backend API to identify products and determine if their manufacturer follows WSAVA nutritional recommendations.

This project is designed as a minimal viable product (MVP) to help cat owners make more informed decisions when choosing cat food.

---

## Features

- Scan cat food barcodes using the phone camera
- Identify the product via the CatFoodCheck API
- Check if the brand complies with WSAVA guidelines
- Simple and lightweight Flutter interface

---

## Tech Stack

- **Flutter** – Mobile app framework
- **HTTP** – API communication
- **barcode_scan2** – Barcode scanning

---

## Getting Started

### Prerequisites

You need:

- Flutter SDK
- Android Studio or VS Code
- Android device or emulator

Check your setup with:

```bash
flutter doctor
```

### Installation

Clone the repository:

```bash
git clone https://github.com/your-username/catfoodcheck-app.git
cd catfoodcheck-app
```

Install dependencies:

```bash
flutter pub get
```

### Running the App

Connect an Android device or start an emulator, then run:

```bash
flutter run
```

The application will install and launch on the connected device.

### Building an APK

To generate an installable Android APK:

```bash
flutter build apk
```

The generated APK will be located at:
```
build/app/outputs/flutter-apk/app-release.apk
```
You can copy this file to your phone and install it manually.

### API Configuration

The app connects to the CatFoodCheck backend API.

Example endpoint:

```
GET https://your-backend-url/scan/{ean}
```

Example response:

```json
{
  "product": "Sterilised 37",
  "brand": "Royal Canin",
  "wsava": true
}
```

The app displays whether the scanned product complies with WSAVA guidelines.

### Backend

This mobile app depends on the CatFoodCheck API backend.

Backend repository:

```
catfoodcheck
```

The backend is built with FastAPI and deployed on Render.

### Project Structure

```
lib/
  main.dart
```

Future versions may include:
- Product history
- Better UI components
- Alternative WSAVA recommendations
- Product nutritional information

## License

This project is licensed under the MIT License - see the LICENSE file for details.
# HRMS + Manager Feedback Monorepo

Base monorepo for an HRMS and manager feedback system.

## Apps

- `mobile-app` - Flutter mobile application.
- `backend` - Node.js, Express, and TypeScript API.
- `hr-admin-web` - Vite, React, and TypeScript admin portal.

## Prerequisites

- Node.js 20+
- npm 10+
- Flutter 3+

## Install

```bash
npm install
cd mobile-app
flutter pub get
```

## Backend

```bash
cp backend/.env.example backend/.env
npm run backend:dev
```

The API starts on `http://localhost:4000` by default.

Health check:

```bash
curl http://localhost:4000/health
```

Other backend commands:

```bash
npm run backend:build
npm run backend:start
```

## HR Admin Web

```bash
cp hr-admin-web/.env.example hr-admin-web/.env
npm run web:dev
```

The admin portal starts on `http://localhost:5173` by default.

Other web commands:

```bash
npm run web:build
npm run web:preview
```

## Mobile App

Android emulator:

```bash
cd mobile-app
flutter run
```

Flutter web (start the backend first):

```bash
cd mobile-app
flutter run -d chrome --web-port=8080
```

The app selects local API defaults by platform: `http://10.0.2.2:4000` on an
Android emulator and `http://localhost:4000` on web and the iOS simulator. For
a physical device or deployed environment, override it with
`--dart-define=API_BASE_URL=https://api.example.com`.

## Quality

```bash
npm run lint
npm run format
cd mobile-app && flutter analyze
```

## Structure

```text
backend/
  src/
    config/
    controllers/
    middleware/
    models/
    routes/
    services/
    utils/
hr-admin-web/
  src/
    components/
    hooks/
    layouts/
    pages/
    routes/
    services/
    utils/
mobile-app/
  lib/
    core/
    features/
    routes/
    services/
    shared/
```

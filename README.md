# Khmer Compass

Khmer Compass is a Flutter app for discovering Cambodian destinations, culture,
and travel information.

## Architecture

The app uses a feature-first structure:

- `lib/core/` contains cross-feature routing, theme, and utilities.
- `lib/shared/` contains reusable widgets and layouts.
- `lib/features/` groups each feature's data, domain, and presentation code.
- `lib/app.dart` configures the application; `lib/main.dart` starts it.

Screens should delegate state to feature providers and obtain data through
repositories. The router in `lib/core/routing/` defines navigation and does not
implement screens. Feature data can use mock repositories until API
repositories are needed.

The Map tab currently uses sample destination coordinates and OpenStreetMap
tiles. It requires an internet connection; review the OpenStreetMap tile usage
policy and use a suitable managed tile provider before production use.

## Development

Run the app with `flutter run`. Check the project with `flutter analyze` and
`flutter test`.

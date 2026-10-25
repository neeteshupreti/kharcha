# Kharcha

A calm, local-first expense and savings tracker for **Android**, **Linux**, and
**Web**. No accounts, no backend, no analytics — everything is stored on the
device.

<img src="kharcha.png" alt="Kharcha screenshot" width="512" />

## Features

- **Track expenses** — add, edit, and delete expenses (amount, category, date,
  optional note). Eight built-in categories keep things tidy.
- **Track savings** — log savings entries across five categories (Cash, Bank,
  Investment, Piggy Bank, Other) with the same ease.
- **Dashboard** — monthly spend vs. savings totals, a running net balance, and
  a newest-first timeline that blends every ledger entry into one view.
- **Insights** — month-by-month comparison, daily average, category breakdown,
  and a six-month history. A tab switch lets you view the same details for
  savings.
- **Filters** — narrow expenses or savings by date range and category, shown as
  removable chips.
- **Settings** — currency selector (9 supported, including NPR, USD, EUR, INR,
  JPY, GBP), theme (Light / Dark / System), and a one-tap "Clear all data".
- **Robust UX** — empty, loading, and error states; confirmation dialogs before
  every destructive action; inline validation with specific messages.

## Quick start

Requires [Flutter](https://docs.flutter.dev/get-started/install) 3.24 or newer
(Dart 3.5+).

```sh
flutter pub get
flutter run -d chrome        # Web
flutter run -d linux         # Linux desktop
flutter run -d android       # Android (requires a connected device or emulator)
```

## Useful commands

```sh
flutter analyze          # Lint
flutter test             # Run unit tests
flutter build apk          # Release APK for Android
flutter build appbundle    # Release App Bundle for Play Store
```

## Project structure

```
lib/
  main.dart                 Entry point, opens storage
  app.dart                  Providers and MaterialApp
  core/
    theme/                  Tokens, semantic colours, ThemeData
    utils/                  Date helpers, formatters, validators
    widgets/                Empty state, confirm dialog, snack bar, charts
  data/                     SQLite and preferences repositories
  models/                   Expense, saving, categories, currency, filters
  features/
    shell/                  Bottom navigation (Home, Expenses, Savings, Insights, Settings)
    home/                   Dashboard with month summary and combined timeline
    expenses/               Controller, form, filter sheet, list items
    savings/                Controller, form, filter sheet, list items
    insights/               Monthly summary with tab view for expenses & savings
    settings/               Preferences and data management
test/
  validators_test.dart      Parsing, formatting, and model round-trip tests
  controller_test.dart      Expense & saving controller logic tests
  database_smoke_test.dart  SQLite integration smoke test
```

## Design decisions

**State management: Provider.** Three small `ChangeNotifier`s (settings,
expenses, savings) cover the whole app. Riverpod would add ceremony without a
benefit at this size.

**Storage:** `sqflite` (with `sqflite_common_ffi` / `sqflite_common_ffi_web` for
Linux and Web) for structured expense and saving records; `shared_preferences`
for the two tiny preference values (theme, currency). The controllers keep the
full list in memory (a personal ledger stays small) and write through to SQLite.

**Money is stored as integer minor units** (cents, or whole yen for JPY), never
as floating point, so sums are always exact. Dates are stored as `yyyy-MM-dd`
text, which sorts and filters correctly and is unaffected by time zones or
daylight saving.

**Currency selector changes display only.** Existing amounts are not converted.
The Settings screen says so explicitly.

**Categories are fixed.** Eight expense categories and five saving categories
keep the breakdown readable. Categories are stored by name, and unknown names
fall back to "Other".

**Font: platform default** (SF on Linux, Roboto on Android, sans-serif on Web).
It needs no bundled asset, renders crisply, and respects the user's system
settings. Amounts use tabular figures so columns line up.

**Future dates are not allowed** when adding or editing entries.

## Design system

All visual decisions live in `lib/core/theme/`:

| File | Purpose |
| --- | --- |
| `tokens.dart` | Spacing (4/8/12/16/24/32), radii (8/10/12), sizes, type scale, and the two hand-tuned colour palettes |
| `app_colors.dart` | `ThemeExtension` for semantic colours not in `ColorScheme` |
| `app_theme.dart` | Builds the light and dark `ThemeData` and all component themes |

Widgets read from the theme and tokens; no colours, sizes, or font styles are
hardcoded in feature code.

- **Type:** display 36, title 20/16, body 16/14, caption 12, in three weights
  (400, 500, 600).
- **Colour:** off-white and near-black neutrals, one muted green accent used for
  the primary action and selection. Dark mode uses `#0E0E10` with raised
  surfaces stepping lighter, rather than pure black.
- **Contrast:** text was chosen to meet WCAG AA (4.5:1) in both themes. Bars
  and tiles have adjacent text labels, so meaning never depends on colour alone.
- **Touch targets:** buttons, icon buttons, chips, list rows, and the
  navigation bar are at least 48dp. Layouts wrap or ellipsise rather than clip,
  so larger text sizes from `MediaQuery.textScaler` are respected.
- **Feedback:** subtle ink press states, light haptics on save and selection, a
  medium haptic when a destructive action is confirmed, and a smooth 300 ms
  theme cross-fade.

## Error handling

Storage failures never crash the app. Repository errors become a
`StorageException` with a user-safe message. Loading errors show a retry state,
failed saves and deletes show a snackbar, and a failure to persist a preference
is reported while the choice still applies for the session.

## Releases

Pre-built APK files are published in the
[GitHub Releases](https://github.com/neeteshupreti/kharcha/releases) section.

## License

This project is available as-is. See the source for details.
